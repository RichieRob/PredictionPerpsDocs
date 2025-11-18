---
comments: true
slug: unified-real-liquidity-comparison
title: Unified Real Liquidity — Comparison with Existing Systems
---

## Definitions (Used Throughout This Document)

To avoid confusion with AMM “markets” such as ETH–USDC pools,  
this documentation uses **Domain** as the core unit of prediction.

### **Ledger**
The system that stores real USDC for each Market Maker (MM)  
and enforces solvency across all actions.  
The Ledger does **not** compute prices.

### **Market Maker (MM)**
An entity (usually a smart contract instance) that deposits USDC  
into the Ledger to support trading inside one or more Domains.

### **Domain**
A **zero-sum leaderboard** (also called a pie) consisting of multiple **Positions**.  
Examples:  
- “Which fruit will be most popular?” → A/B/C/D  
- “Which creator will have the highest rating?”  
- “Which candidate will win?”

A Domain replaces the overloaded term **market**.  
This avoids confusion with token-pair AMM markets (e.g., ETH–USDC).

### **Position**
One entry within a Domain.  
Examples: Apple, Banana, Cucumber, Dragon.

### **Direction**
Every Position has two Directions:
- **Back(Position)** — exposure toward that Position winning.
- **Lay(Position)** — exposure against that Position (equivalent to backing all other Positions).

### **Unified Real Liquidity**
A single USDC deposit by an MM backs **all Positions**,  
in **all Directions**, within a Domain — simultaneously —  
subject only to the Ledger’s global solvency rule.

### **AMM (Automated Market Maker)**
A pricing module (e.g., LMSR) that determines exposure changes inside a Domain.  
The AMM doesn't hold real collateral; it just sets prices for how its willing for its collateral held in the ledger to change.

---

# 1 · How Existing Systems Handle Real Collateral

Below we compare existing architectures — purely at the level of **real collateral flow**,  
not pricing curves or synthetic liquidity.

---

## Gnosis Conditional Tokens (CTF)  
https://github.com/gnosis/conditional-tokens-contracts

**How it works**
- 1 USDC is **split** into ERC-1155 outcome tokens for every Position.  
- A “complete set” must be **merged** back to return USDC.  
- All liquidity becomes **materialised tokens** held per Position.

**Why this does *not* unify liquidity**
- Real collateral is tied to specific outcome tokens.  
- Token balances exist per domain and per Position.  
- Collateral cannot automatically back all Positions or Directions simultaneously.  
- Balanced exposure only cancels when users explicitly merge tokens.

---

## Systems Built on CTF (e.g., Omen)

**How it works**
- Each Domain holds its own ERC-1155 balances of outcome tokens.  
- MMs or LPs lock outcome tokens into specific markets.  
- Omen’s architecture is documented here:  
  https://docs.omen.eth.limo/docs/how-it-works

**Why this does *not* unify liquidity**

In CTF-based systems, liquidity is fragmented **inside the same Domain**:

- Every Position has its own ERC-1155 outcome token.  
- Back and Lay directions are entirely separate token flows.  
- Liquidity is locked inside these *materialised token balances*.  
- Balanced exposure does **not** auto-cancel — it requires explicit `merge` calls.  
- Market makers must run bots to continuously split and merge sets just to keep the Domain solvent.  
- As a Domain grows (5, 10, 20, 50 Positions), the amount of token juggling grows explosively.

**Result:**  
Even within a single Domain, liquidity cannot unify.  
It is trapped in separate buckets (Position A tokens vs Position B tokens vs direction flows),  
making it impossible to support large Domains or deep liquidity without enormous fragmentation.

---

## Azuro's LiquidityTree  
https://github.com/Azuro-protocol/LiquidityTree

**How it works**
- A single LP pool holds collateral.  
- LiquidityTree distributes settlement profit/loss **after** results resolve.

**Why this does *not* unify liquidity**
- It only allocates capital at **settlement**, not during live exposure.  
- Real collateral is **not** used as the counterparty to Back/Lay trades.  
- No Position-level solvency or domain-level exposure tracking.

---

## Traditional AMM Pools (Uniswap, Curve)

**How it works**
- Collateral is locked inside a specific liquidity pool:  
  ETH–USDC, FRAX–USDC, etc.

**Why this does *not* unify liquidity**
- Liquidity is confined to a single trading pair (pool).  
- Capital in one pool cannot support any other.  
- No mechanism for shared collateral across Positions.

---

# 2 · The Shared Limitation Across All Existing Systems

All these systems suffer from **capital compartmentalisation**.

Real collateral is:

- split into tokens (CTF)
- siloed per Domain (Omen)
- reserved for settlement (Azuro)
- locked inside isolated pools (AMMs)

This means:

- Liquidity cannot flow freely across Positions.  
- Back and Lay directions must be separately collateralised.  
- Balanced exposure cannot automatically recycle collateral.  
- Each Domain requires its own dedicated deposit.

**They unify *logic* or *settlement*,  
but none unify *real live collateral* for Position exposure.**

---

# 3 · How Our Ledger Achieves Unified Real Liquidity

In our architecture:

### Real USDC deposited by an MM enters a **single shared balance array**  
for that Domain.

This collateral instantly becomes the backing for:

- **Back(Position)** in any Position  
- **Lay(Position)** in any Position  
- buying Back  
- selling Back  
- buying Lay  
- selling Lay  

all from the **same** pool of real collateral.

### No tokens are split.  
### No tokens are merged.  
### No collateral is moved between buckets.  
### No Position requires a dedicated budget.

Balanced exposure cancels automatically inside the ledger  
without minting or burning anything.

The only requirement is the global solvency rule:

> The worst-case Position must remain ≥ 0.

This single inequality ensures the Ledger can always honour  
every Position and every Direction, simultaneously.

This is **unified real liquidity**.

---

# 4 · The Crucial Distinction: Ledger vs AMM

This is where our system truly departs from all existing architectures.

### In existing systems:
- AMM logic *holds collateral* (Uniswap).  
- Token balances *are* collateral (CTF/Omen).  
- Settlement logic *owns LP capital* (Azuro).  

That fusion prevents unified liquidity.

---

### In our system:
- **Ledger** = collateral + solvency  
- **AMM** = prices + exposure changes  

The AMM only computes *how exposure should change*.  
The Ledger decides *whether it is allowed* (solvency).  
The AMM never touches real collateral.

This separation is what allows:

- one USDC deposit to back all Positions inside a Domain  
- in every Direction  
- subject only to one solvency constraint  
- without moving collateral or minting/burning tokens

No previous system has this architectural split.

---

# 5 · Summary Table

| System | Collateral Model | Why Liquidity Isn't Unified | Our Difference |
|--------|------------------|-----------------------------|----------------|
| **Gnosis CTF** | Collateral split into outcome tokens | Outcome tokens trap liquidity; per-domain silos | Collateral stays abstract; never split unless withdrawing |
| **Omen (CTF)** | ERC-1155 outcome balances per domain | Liquidity tied to token balances per position | One shared balance array backs all positions & directions |
| **Azuro** | Global settlement pool | Collateral not used for live exposure | Ledger backs live Back/Lay exposure in real time |
| **Uniswap/Curve** | Pool-specific collateral | Liquidity isolated per pair | No pools; unified collateral backing all positions |
| **General AMMs** | AMM holds collateral | Pricing + collateral fused | AMM separated from Ledger entirely |

---

# Closing Statement

Existing architectures unify **logic**, **payouts**, or **settlement**,  
but they do **not** unify *real collateral* during live trading.

By separating the **Ledger** (real collateral + solvency) from the **AMM** (pricing + exposure),  
our system allows one pool of USDC to safely back  
every Position, in every Direction, across an entire Domain.

This is **true unified real liquidity**.

---

--8<-- "link-refs.md"
