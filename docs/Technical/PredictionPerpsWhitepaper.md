---
comments: true
slug: prediction-perps-whitepaper
title: Prediction Perps Whitepaper
---

# Prediction Perps — Perpetual, Zero-Sum Leaderboards

**Prediction Perps** creates *tradable leaderboards*: n-dimensional, on-chain markets where many positions continuously compete for a share of a **fixed total value (typically 1 USDC)**. Prices are maintained by a closed-form **LMSR** AMM and positions are always redeemable into that fixed total, ensuring **zero-sum accounting** without oracles, funding rates, or settlement events. Markets **never resolve**—they run indefinitely.

Start here: [What Is It](FullReadMe/WhatIsIt.md) · [Technical Overview](FullReadMe/TechnicalReadMe.md)

---

## 1) The Idea

Traditional prediction markets hinge on an external event and a resolution (often via an oracle). **Prediction Perps** removes resolution entirely. Each market is a live leaderboard: when traders buy one position, its share of the fixed pot increases while others decrease—**the pot itself never changes** (e.g., always 1 USDC). This yields:

- **Perpetual** markets — they never close or resolve.  
- **Zero-sum conservation** — values only redistribute among positions.  
- **Always-on pricing** via LMSR, enabling entry/exit at any time.  
- **Instant liquidity** at creation via **Synthetic Liquidity**.

Read: [What Is It](FullReadMe/WhatIsIt.md) · [Zero-Sum](FullReadMe/ZeroSum.md)

---

## 2) Core Mechanics

### Always-Priced via LMSR (O(1))
The AMM implements a **closed-form LMSR** with **BACK** (buy outcome *i*) and **true LAY** (buy *not-i*) orders. State updates are **O(1)** using a cached decomposition of the exponential sum, so pricing remains efficient as markets grow.

- Details: [AMM (LMSR as O(1))](FullReadMe/AMM.md)  
- Contract surface: [AMM.sol](Contracts/AMM.sol.md)

### Zero-Sum by Construction
At any moment, the basket of positions can be combined/split to a **fixed redeemable amount (1 USDC)**. That invariant enforces conservation of value across the leaderboard—profit in one position is necessarily loss spread over the rest.

- Concepts & math: [Zero-Sum](FullReadMe/ZeroSum.md)

### Perpetual, No Resolution
There is **no event**, **no oracle**, and **no settlement**. Prices reflect current demand across positions. Traders can open/close, rebalance between competitors, or redeem baskets back to the fixed total—**forever**.

- See: [What Is It](FullReadMe/WhatIsIt.md)

---

## 3) Liquidity & Accounting

### Ledger (MM Balances Only)
The **Ledger** maintains each **market maker’s (MM) balances** and enforces deterministic checks on MM-side accounting and invariants. It underpins issuance/redemption paths that keep the market’s **constant redeemability** intact while preventing unbacked exposure.

- Concepts: [Ledger Overview](FullReadMe/Accounting/StandardLiquidity/LedgerOverview.md)  
- Accounting details: [Ledger Accounting](FullReadMe/Accounting/StandardLiquidity/LedgerAccounting.md)  
- Contract: [Ledger.sol](Contracts/Ledger.sol.md) · [Contracts Index](ContractsIndex.md)

### Synthetic Liquidity (Instant Start)
Because they dont resolve markets can open with **zero real capital** using **ISC** (internal synthetic collateral). The *designated market maker* quotes from block one. As real USDC later arrives, it **fills/repays ISC** first and then grows real depth—prices and invariants remain continuous.

- Overview: [Synthetic Liquidity](FullReadMe/Accounting/SyntheticLiquidity/SyntheticOverview.md)  
- Algorithms: [Synthetic Accounting](FullReadMe/Accounting/SyntheticLiquidity/SyntheticAccounting.md) · [Principles](FullReadMe/Accounting/SyntheticLiquidity/SyntheticPrinciples.md)

### Solvency, Priority, and Safety
Solvency checks and a heap-based priority structure ensure efficient processing for redemptions and health tracking. Invariants guarantee constant redeemability to 1 USDC across the leaderboard.

- Concepts: [Solvency](FullReadMe/Solvency.md) · [Solvency Accounting](FullReadMe/SolvencyAccounting.md)  
- Data structure: [Heap Logic](FullReadMe/HeapLogic.md)

---

## 4) Trading Flows (No Oracles, No Funding, No Settlement)

//NB with Market instantiation we need to think about the DMM, LMSR and the initial weightings that are put on things...
// this requires some rethinking of the AMM.sol code 
// additionally we need to think about how the AMM handles expanding markets (other bucket)
// additionally we need to check how the Ledger and AMM speak to each other and name the positions. 

1. **Market instantiation** 
   - Define the set of positions (competitors on the leaderboard).  
   - **Synthetic Liquidity** makes the market tradable immediately.  
   - Links: [MarketIntialisation](./MarketIntialisation.md) · [Synthetic Liquidity](FullReadMe/Accounting/SyntheticLiquidity/SyntheticOverview.md)

2. **Trade (BACK or LAY) against LMSR**  
   - **BACK i** increases position *i*’s share; **LAY i** increases the complement’s share.  
   - AMM updates state in **O(1)** and performs invariant checks (with MM-side accounting in the **Ledger**).  
   - Links: [AMM](FullReadMe/AMM.md) · [Ledger Accounting](FullReadMe/Accounting/StandardLiquidity/LedgerAccounting.md)

3. **Issue / Redeem**  
   - Positions combine/split to maintain **constant redeemability (1 USDC)** for the basket.  
   - This is the enforcement point for **zero-sum conservation**.  
   - Links: [Zero-Sum](FullReadMe/ZeroSum.md)

4. **Liquidity growth**  
   - As real USDC arrives, it **replaces ISC** and then increases depth; prices remain consistent.  
   - Links: [Synthetic Accounting](FullReadMe/Accounting/SyntheticLiquidity/SyntheticAccounting.md)

> There are **no funding rates**, **no oracle calls**, and **no resolution steps**. The market is continuous and self-contained.

---

## 5) Composability

All logic is modular and contracts expose clean surfaces for integration. This enables:

- **Portfolio construction** across leaderboards (baskets of positions).  
- **Derived indices** and signals from share trajectories.  
- **Protocol integrations** that rely on MM accounting and LMSR pricing.

Start from: [Contracts Index](ContractsIndex.md) · [Technical Overview](FullReadMe/TechnicalReadMe.md)

---

## 6) Security Model

- **Deterministic invariants**: every transition preserves conservation and redeemability.  
- **Stateless, gas-conscious libraries** for core math and accounting.  
- **No privileged resolution or price control** paths.  
- Planned artifacts: specs & audits.  
  - See: [Documents Needed](FullReadMe/DocumentsNeeded.md)

---

## 7) Why It Matters

Prediction Perps generalizes prediction markets into **perpetual, event-less leaderboards**.  
It delivers an **oracle-free**, **zero-sum**, **always-liquid** primitive where prices continuously express collective belief about *relative* outcomes across many competitors—indefinitely.

Dive deeper:
- [What Is It](FullReadMe/WhatIsIt.md) · [Technical Overview](FullReadMe/TechnicalReadMe.md)  
- [AMM (LMSR O(1))](FullReadMe/AMM.md) · [Zero-Sum](FullReadMe/ZeroSum.md)  
- [Solvency](FullReadMe/Solvency.md) · [Solvency Accounting](FullReadMe/SolvencyAccounting.md)  
- [Synthetic Liquidity](FullReadMe/Accounting/SyntheticLiquidity/SyntheticOverview.md)  
- [Ledger Overview](FullReadMe/Accounting/StandardLiquidity/LedgerOverview.md) · [Ledger Accounting](FullReadMe/Accounting/StandardLiquidity/LedgerAccounting.md)  
- [Contracts Index](ContractsIndex.md)

--8<-- "link-refs.md"
