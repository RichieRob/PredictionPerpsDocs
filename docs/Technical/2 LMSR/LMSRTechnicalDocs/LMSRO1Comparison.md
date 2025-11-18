---
comments: true
slug: lmsr-o1-comparison
title: O(1) LMSR — Comparison with Existing Implementations
---

## Definitions (Used in This Document)

### **LMSR (Logarithmic Market Scoring Rule)**  
A cost-function AMM (Hanson, 2003 & 2007) where prices come from normalized exponentials of exposure.

### **Classical LMSR (O(n))**  
Stores an array of outcome shares and recomputes the full LMSR sum across every outcome every time a trade or quote occurs.

### **Prediction Perps O(1) LMSR**  
Keeps LMSR’s math **exact**, but stores the LMSR partition in **cached state**, updating only 2 or 3 cached states per transaction.

No loops.  
Quotes and trades are **O(1)**.

---

# 1 · Existing Systems and Their LMSR / Non-LMSR Implementations

Below we review all major architectures used in prediction markets today.

---

## Gnosis LMSR (Baseline Hanson Implementation)
**Repo:**  
https://github.com/gnosis/conditional-tokens-market-makers

**Pattern**
- Stores \(q_i\) vector.  
- Computes \(Z = \sum_i e^{q_i/b}\) by looping every trade.  
- **O(n)** compute cost.

The canonical public LMSR implementation.

---

## Omen (CTF + LMSR Wrapper)
**Repo:**  
https://github.com/gnosis/conditional-tokens-market-makers

**Pattern**
- Wraps Gnosis LMSR directly.  
- CTF outcome tokens dictate structure.  
- Still requires looping through all outcomes.

**O(n)**.

---

## Fair Prediction Market Maker (FPMM)
**Repo:**  
https://github.com/protofire/omen-exchange

**Pattern**
- Not LMSR.  
- Vector-based AMM requiring full recomputation.  
- **O(n)** per trade.

---

## Azuro Protocol (Non-LMSR)
**Contracts:**  
https://github.com/Azuro-protocol/Azuro-v2-public

**Pattern**
- Sports-model engine.  
- Not LMSR.  
- Not cost-function-based.  
- Updates require touching multiple outcomes or tree paths.

---

## **Polymarket (CLOB — Not an AMM, Not LMSR)**  
https://wiki.polymarket.com

**How it works**
- Uses a **central limit order book (CLOB)**.  
- YES and NO are **separate books**.  
- Prices = best bid/ask, not a formula.

**Why this is not LMSR**
- Order Book Based

**Why this does not unify liquidity**
- Liquidity exists per order book.  
- No shared liquidity across outcomes.  
- No algorithmic counterparty like an AMM.

**TLDR:**  
Highly efficient CLOB, but **not LMSR**, **not an AMM**, and **not unified liquidity**.

---

## Augur  
**Repo:**  
https://github.com/AugurProject/augur

**Pattern**
- Order book based.  
- Not LMSR.

---

# 2 · Shared Limitation Across All Existing LMSR Implementations

Gnosis, Omen, FPMM and most academic examples treat the LMSR partition function

\[
Z = \sum_i e^{q_i/b}
\]

as a **derived value** that must be recomputed each time.

Result:

- Quotes = **O(n)**  
- Trades = **O(n)**  
- Prices = **O(n)**  
- Gas grows linearly with outcome count  
- Large multi-outcome markets become impractical  

None store the LMSR exponential structure as **maintained state**.

---

# 3 · How Prediction Perps Implements LMSR in O(1)

We keep LMSR’s mathematics **unchanged and exact**.

But use cached states to ease the calculations.

No loops.  
No summations.  
No recomputation of exponentials except for the affected slot.

Quotes and prices read directly from the cached state.

---

# 4 · Architectural Distinction

### Existing LMSR Implementations  
- Recompute the partition function from scratch.  
- Treat \(q_i\) as canonical state.  
- Gas and compute scale with outcome count.

### Polymarket  
- No cost function at all.  
- No algorithmic counterparty.  
- Liquidity is fragmented across order books.

### Prediction Perps  
- Treats LMSR’s decomposition as *canonical on-chain state*.  
- Updates only what changed.  
- First practical LMSR for **large multi-position leaderboards**, not just tiny outcome sets.

---

# 5 · Summary Table

| System | AMM Type | Complexity | Why Not O(1)? |
|--------|----------|------------|----------------|
| **Gnosis LMSR** | LMSR | O(n) | Recomputes full partition sum |
| **Omen (CTF)** | LMSR wrapper | O(n) | Outcome tokens force loops |
| **FPMM** | Non-LMSR | O(n) | Full vector update |
| **Azuro** | Non-LMSR | O(n) | Custom model, no cached state |
| **Polymarket** | **CLOB** | Matching O(1)/O(log n) | Not an AMM; fragmented liquidity |
| **Augur** | Order book | O(log n) | Not LMSR |
| **Prediction Perps** | **Exact LMSR with cached state** | **O(1)** | Updates only G, R_k, S |

---

# Closing Statement

No existing system — LMSR-based or otherwise — maintains the LMSR partition function as a **living on-chain state machine**.

Prediction Perps is the first to implement **exact LMSR**,  
but with an architecture that makes both **quoting** and **execution** run in **O(1)** time.

This unlocks large-scale leaderboards and huge multi-position markets that were previously infeasible.

--8<-- "link-refs.md"
