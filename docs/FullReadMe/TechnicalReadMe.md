# Technical Overview

## 1 · What Is a Prediction Perps Market?

A Prediction Perps market is an **n-dimensional, perpetual, zero-sum market** that can operate with **zero initial liquidity**.

For a high-level introduction to the concept of Prediction Perps, see [**What Is It?**](WhatIsIt.md).  

This document describes the **technical framework** that enables those markets to function — how liquidity, solvency, and pricing are maintained continuously and safely on-chain.

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

Follow the links for full details of each mechanism.

| Mechanism | Description |
|------------|-------------|
| [**Unified Liquidity**](./Accounting/StandardLiquidity/UnifiedLiquidity.md) | All positions share a single pool of capital, enabling efficient price discovery and preventing the fragmentation typical of multi-pool AMMs. |
| [**Solvency**](Solvency.md) | Every trade, issuance, or redemption is validated by the ledger to ensure all markets remain solvent by design. |
| [**Zero-Sum Enforcement**](ZeroSum.md) | The combined value of all positions in a market is constant. This rule is enforced automatically at the ledger level, keeping every market internally balanced. |
| [**O(1) LMSR Market Maker**](AMM.md) | The pricing engine implements an optimized form of the LMSR (Logarithmic Market Scoring Rule), updated in **constant time (O(1))** regardless of market size. |
| [**Synthetic Liquidity (ISC)**](./Accounting/SyntheticLiquidity/SyntheticOverview.md) | Markets can launch with **no real USDC**, using internal synthetic credit that behaves like real liquidity until genuine capital arrives. |

---

## 4 · Core Contracts

Prediction Perps is built around three primary smart contracts.  

| Contract | Core Role |
|-----------|-----------|
| [**Ledger.sol**](../Contracts/Ledger.sol.md) | • Central accounting and solvency enforcement.<br>• Tracks all balances and verifies zero-sum invariants.<br>• Safely moves both real and synthetic capital (ISC).<br>• Executes trades **only** when instructed by a market maker. |
| [**AMM.sol**](../Contracts/AMM.sol.md) | • Calculates prices and validates trades using the optimized **O(1) LMSR** algorithm.<br>• Determines whether each trade can execute and at what price.<br>• Holds no balances; delegates all settlement to the Ledger. |
| [**PositionToken1155.sol**](../Contracts/PositionToken1155.sol.md) | • Represents all Back/Lay positions as ERC-1155 tokens.<br>• Each token ID encodes `(marketId, positionId, side)` and auto-generates a human-readable ticker.<br>• Only the Ledger can mint or burn. <br>• Users may freely transfer tokens. |

---


### Summary of Responsibilities

| Layer | Function |
|--------|-----------|
| **AMM / Market Makers** | Decide *what happens* — set prices, validate trades, and instruct the Ledger. |
| **Ledger** | Ensure *it happens safely* — maintain solvency, enforce zero-sum rules, and manage both real and synthetic liquidity. |
| **PositionToken1155** | Represent *what users hold* — standardized Back/Lay tokens with stable IDs and tickers. |

## 5 · Further Reading

- [**Ledger Accounting**](../LedgerAccounting.md) — internal balance flow and solvency rules.  
- [**Synthetic Liquidity**](../SyntheticLiquidity.md) — how ISC works and how synthetic collateral transitions to real USDC.  
- [**Heap Logic**](../HeapLogic.md) — O(1) tilt tracking and solvency enforcement.  
- [**Contracts Index**](../contracts/) — all Solidity contract documentation.  

---
