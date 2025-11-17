---
comments: true
---

# Contracts Index

Quick index of contracts and libraries with one‑line descriptions, linked to their detailed `.sol` files.

## Core Contracts

- **[LMSRMarketMaker.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LMSRMarketMaker.sol)** — Automated Market Maker state machine and pricing interface (Back/Lay, cost updates, cached sums).
- **[Ledger.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/Ledger.sol)** — Custodies USDC, tracks budgets and balances, and enforces solvency and issuance rules.
- **[PositionToken1155.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/PositionToken1155.sol)** — ERC‑1155 position tokens for Back/Lay shares with minimal surface area.

## Interfaces

- **[IERC20Permit.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/IERC20Permit.sol)** — ERC‑2612 Permit interface for signature‑based approvals.
- **[ILedger.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/ILedger.sol)** — Interface for ledger operations (buy/sell, deposits/withdrawals, accounting views).
- **[IPermit2.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/IPermit2.sol)** — Uniswap Permit2 interface for unified token approvals.
- **[iPositionToken1155.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/iPositionToken1155.sol)** — Interface for the ERC‑1155 position token.

## Ledger Libraries

- **[AllocateCapitalLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/AllocateCapitalLib.sol)** — Tracks and updates market maker allocated vs free collateral.
- **[DepositWithdrawLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/DepositWithdrawLib.sol)** — Handles USDC deposits and withdrawals into the ledger.
- **[HeapLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/HeapLib.sol)** — Block‑min + small top‑heap to maintain the global minimum efficiently.
- **[LedgerLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/LedgerLib.sol)** — Core ledger accounting and invariants shared across contracts.
- **[LiquidityLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/LiquidityLib.sol)** — Liquidity‑related helpers (mint/burn flows, pool adjustments).
- **[MarketManagementLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/MarketManagementLib.sol)** — Create/init markets, store metadata, and manage lifecycle.
- **[RedemptionLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/RedemptionLib.sol)** — Utilities for redemption processes.
- **[SolvencyLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/SolvencyLib.sol)** — Checks and enforces solvency/issuance constraints.
- **[StorageLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/StorageLib.sol)** — Typed storage structs and slots for the ledger system.
- **[TokenOpsLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TokenOpsLib.sol)** — Safe ERC‑1155/20 operations and utility wrappers.
- **[TradingLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TradingLib.sol)** — Handles trading operations and logic.
- **[Types.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/Types.sol)** — Defines core data types and structures.
- **[TypesPermit.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TypesPermit.sol)** — Defines permit-related data types.

## AMM Libraries

- **[LMSRExecutionLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRExecutionLib.sol)** — Executes trades and operations in the LMSR AMM model.
- **[LMSRExpansionLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRExpansionLib.sol)** — Manages expansion logic for LMSR markets.
- **[LMSRHelpersLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRHelpersLib.sol)** — Provides helper functions for LMSR calculations and utilities.
- **[LMSRInitLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRInitLib.sol)** — Handles initialization of LMSR AMM parameters.
- **[LMSRMathLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRMathLib.sol)** — Core mathematical functions for LMSR pricing and computations.
- **[LMSRQuoteLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRQuoteLib.sol)** — Generates quotes and pricing for LMSR trades.
- **[LMSRUpdateLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRUpdateLib.sol)** — Updates LMSR state after trades or events.
- **[LMSRViewLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRViewLib.sol)** — View functions for querying LMSR AMM data.
