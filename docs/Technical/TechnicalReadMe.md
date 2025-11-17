---
comments: true
slug: technical-read-me
title: Technical Read Me
---

# Technical Overview

This document describes the **technical framework** that enables Prediction Perps markets to function — how liquidity, solvency, and pricing are maintained continuously and safely on-chain.

## 1 · What Is a Prediction Perps Market?

A Prediction Perps market is an **n-dimensional, perpetual, zero-sum market** that can operate with **zero initial liquidity**.

[Read more →](WhatIsIt.md).  

---

## 2 · Properties of Prediction Perps Markets

- **Always Priced** — prices exist continuously for every position, allowing valuation at any time.  
- **Instantly Liquid** — trading can begin immediately, even at creation, without external liquidity.  
- **Solvent** — every position is continuously backed and reconciled by the system’s ledger.  
- **Massively Multi-Positional** — hundreds of positions can coexist within a single closed system, all sharing one pool of value.  
- **Zero-Sum** — the combined value of all positions is constant, and this constraint is enforced automatically by the ledger.  
- **Perpetual** — they evolve indefinitely, without any resolution event.

---

## 3 · Core Mechanisms

Prediction Perps achieves its perpetual, zero-sum behaviour through a set of coordinated mechanisms that operate together to maintain liquidity, pricing, and solvency in real time.

### **Unified Liquidity**
All positions within a market draw from a **single shared pool of capital**. This eliminates the capital fragmentation that occurs in traditional multi-pool AMMs and allows efficient price discovery even when hundreds of positions coexist.  
[Read more →](./Accounting/StandardLiquidity/UnifiedLiquidity.md)

---

### **Solvency**
Every trade, issuance, or redemption is validated by the **Ledger**, which continuously enforces collateral coverage for all market makers. The system guarantees that no trade can ever create unbacked exposure — keeping each market solvent by design.  
[Read more →](Solvency.md)

---

### **Zero-Sum Enforcement**
In every market, the **combined value of all positions remains constant**. If one position rises, the others fall proportionally. This invariant is enforced automatically by the Ledger’s internal accounting logic, ensuring perfect conservation of value across all positions.  
[Read more →](ZeroSum.md)

---

### **O(1) LMSR Market Maker**
Pricing is powered by an optimized version of the **Logarithmic Market Scoring Rule (LMSR)**, implemented to update in **constant time (O(1))** regardless of market size. This design keeps pricing responsive and gas-efficient even in massively multi-positional markets.  
[Read more →](AMM.md)

---

### **Synthetic Liquidity (ISC)**
Markets can launch and function **with no real USDC deposited**. The Ledger can assign **Internal Synthetic Collateral (ISC)** to a designated market maker, providing virtual depth for early trading. Over time, ISC is gradually replaced by real capital as traders participate.  
[Read more →](./Accounting/SyntheticLiquidity/SyntheticOverview.md)

---

## 4 · Core Contracts

Prediction Perps is built around three primary smart contracts that work together to maintain pricing, liquidity, and solvency across all markets.

---

### **Ledger.sol**
The **Ledger** is the heart of the system — it handles all accounting, collateral management, and solvency enforcement. It tracks balances for every market maker, validates that trades remain solvent, and ensures the zero-sum invariant always holds. The Ledger also manages both **real** and **synthetic capital (ISC)**, executing trades only when instructed by an authorized market maker.  
[Read more →](../Contracts/Ledger.sol.md)

---

### **AMM.sol**
The **Automated Market Maker (AMM)** calculates prices and validates trades using the optimized **O(1) LMSR** algorithm. It determines whether each trade can execute and at what price — but never holds user balances. All settlement and collateral movement are delegated to the Ledger.  
[Read more →](../Contracts/AMM.sol.md)

---

### **PositionToken1155.sol**
All market positions are represented as ERC-1155 tokens, providing efficient multi-asset support. Each token ID encodes its `(marketId, positionId, side)` and automatically generates a human-readable ticker. Only the Ledger can mint or burn tokens; once issued, users can freely hold or transfer them like any standard asset. 
[Read more →](../Contracts/PositionToken1155.sol.md)

---

### **How They Work Together**

1. **The AMM** decides whether a trade can execute and at what price.  
2. **The Ledger** performs the trade, reallocates liquidity, and checks solvency and zero-sum invariants.  
3. **The PositionToken1155** contract issues or burns the corresponding Back/Lay tokens.  

Together, these contracts ensure every trade is priced, executed, and recorded safely — maintaining real-time solvency and balance across the system.

## 5 - Documentation which is needed but doesnt exist yet

- [**Docs Needed**](DocumentsNeeded.md)

## 6 · Further Reading

- [**ZeroSum**](ZeroSum.md)
- [**Solvency**](Solvency.md)
- [**AMM**](AMM.md)
- [**Unified Liquidity**](./Accounting/StandardLiquidity/UnifiedLiquidity.md)
- [**Synthetic Liquidity**](./Accounting/SyntheticLiquidity/SyntheticOverview.md)

---

--8<-- "link-refs.md"
