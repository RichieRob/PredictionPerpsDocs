# Prediction Perps Documentation

Welcome to the **Prediction Perps** technical documentation.  
This site explains how the system works — from high-level concepts and economic design down to the Solidity implementation that enforces it on-chain.

---

## 📘 Overview

Prediction Perps is a **framework for perpetual, zero-sum markets**.  
Each market represents a live leaderboard where all positions share one fixed pool of value.  
Prices evolve continuously as traders buy and sell, redistributing conviction between positions rather than resolving to an event outcome.

To start with the core idea, see:  
👉 [**What Is It?**](WhatIsIt.md)

---

## 🧩 Technical Architecture

The framework is built around modular, on-chain components that maintain continuous pricing, unified liquidity, and ledger-level solvency.

To Understand the techinal aspects seeL
👉 [**Technical Overview**](TechnicalReadMe.md)
---

## ⚙️ Smart Contracts

Full explanations of contract functionality WIP. However you can browse the contracts here:

| Contract | Purpose |
|-----------|----------|
| [**Ledger.sol**](../Contracts/Ledger.sol.md) | Core accounting, collateral, and solvency enforcement. |
| [**AMM.sol**](../Contracts/AMM.sol.md) | Pricing logic and trade validation using O(1) LMSR. |
| [**PositionToken1155.sol**](../Contracts/PositionToken1155.sol.md) | ERC-1155 Back/Lay token implementation and ticker mapping. |
| [**Libraries**](../Contracts/Libraries/) | Modular Solidity libraries for ledger, liquidity, and trading logic. |

For a complete list, see the [**Contracts Index**](../ContractsIndex.md).

---

**Prediction Perps**  
A perpetual, unified-liquidity market system — designed for scale, safety, and continuous belief expression.

