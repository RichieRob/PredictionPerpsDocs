# Contracts Index

Quick index of contracts and libraries with one‑line descriptions, linked to their detailed `.sol.md` docs.

## Core Contracts

- **[AMM.sol](Contracts/AMM.sol.md)** — Automated Market Maker state machine and pricing interface (Back/Lay, cost updates, cached sums).
- **[Ledger.sol](Contracts/Ledger.sol.md)** — Custodies USDC, tracks budgets and balances, and enforces solvency and issuance rules.
- **[PositionToken1155.sol](Contracts/PositionToken1155.sol.md)** — ERC‑1155 position tokens for Back/Lay shares with minimal surface area.

## Interfaces

- **[IERC20Permit.sol](Contracts/IERC20Permit.sol.md)** — ERC‑2612 Permit interface for signature‑based approvals.
- **[ILedger.sol](Contracts/ILedger.sol.md)** — Interface for ledger operations (buy/sell, deposits/withdrawals, accounting views).
- **[IPermit2.sol](Contracts/IPermit2.sol.md)** — Uniswap Permit2 interface for unified token approvals.
- **[iPositionToken1155.sol](Contracts/iPositionToken1155.sol.md)** — Interface for the ERC‑1155 position token.

## Libraries

- **[AllocateCapitalLib.sol](Contracts/Libraries/AllocateCapitalLib.sol.md)** — Tracks and updates market maker allocated vs free collateral.
- **[DepositWithdrawLib.sol](Contracts/Libraries/DepositWithdrawLib.sol.md)** — Handles USDC deposits and withdrawals into the ledger.
- **[HeapLib.sol](Contracts/Libraries/HeapLib.sol.md)** — Block‑min + small top‑heap to maintain the global minimum efficiently.
- **[LedgerLib.sol](Contracts/Libraries/LedgerLib.sol.md)** — Core ledger accounting and invariants shared across contracts.
- **[LiquidityLib.sol](Contracts/Libraries/LiquidityLib.sol.md)** — Liquidity‑related helpers (mint/burn flows, pool adjustments).
- **[MarketManagementLib.sol](Contracts/Libraries/MarketManagementLib.sol.md)** — Create/init markets, store metadata, and manage lifecycle.
- **[RedemtionLib.sol](Contracts/Libraries/RedemtionLib.sol.md)** — Library: utilities for Redemtion .
- **[SolvencyLib.sol](Contracts/Libraries/SolvencyLib.sol.md)** — Checks and enforces solvency/issuance constraints.
- **[StorageLib.sol](Contracts/Libraries/StorageLib.sol.md)** — Typed storage structs and slots for the ledger system.
- **[TokenOpsLib.sol](Contracts/Libraries/TokenOpsLib.sol.md)** — Safe ERC‑1155/20 operations and utility wrappers.
- **[TradingLib.so](Contracts/Libraries/TradingLib.so.md)** — Module: Trading Lib.
- **[Types.sol](Contracts/Libraries/Types.sol.md)** — Module: Types.
- **[TypesPermit.sol](Contracts/Libraries/TypesPermit.sol.md)** — Module: Types Permit.
