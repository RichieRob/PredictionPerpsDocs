# Ledger Accounting

This document details the internal accounting of the ledger,
specifically how `freeCollateral`, `AllocatedCapital`, and `tilt` are updated
to manage Back and Lay token operations,
as implemented in the provided Solidity contracts.
It assumes familiarity with the Ledger Overview
and focuses solely on the accounting mechanics for these operations.

## Innovation

The ledger's accounting revolutionizes liquidity provision by unifying the market maker's supplied liquitidy.
 
This unlocks unparalleled flexibility in providing liquidity within and across multi-position markets simultaneously.

## Accounting Components

The ledger uses three variables in `StorageLib.sol` 
to track the market maker's (MM) balance
for each market (`marketId`) and position (`positionId`):

- **Free Collateral**: `mapping(uint256 => uint256) freeCollateral`
  tracks unallocated USDC for an MM (`mmId`),
  representing liquid capital.

- **Allocated Capital**: `mapping(uint256 => mapping(uint256 => int256)) AllocatedCapital`
  tracks the net USDC committed to a market.
  Positive values indicate USDC deposited;
  negative values indicate profit received.

- **Tilt**: `mapping(uint256 => mapping(uint256 => mapping(uint256 => int128)) tilt`
  adjusts the available shares for a specific position.
  Positive `tilt` increases available shares;
  negative `tilt` decreases them.

The available shares for a position \( k \), denoted \( H_k \), are:

\[
H_k = \text{freeCollateral}[\text{mmId}] + \text{AllocatedCapital}[\text{mmId}][\text{marketId}] + \text{tilt}[\text{mmId}][\text{marketId}][k]
\]

## Accounting for Back and Lay Tokens

The ledger updates `freeCollateral`, `AllocatedCapital`, and `tilt`
in `TradingLib.sol`
to reflect the issuance and receipt of Back and Lay tokens,
matching the operations in the Ledger Overview.
Solvency enforcement via `SolvencyLib.sol`
is applied after token operations
to ensure \( H_k \geq 0 \).

### Back Token Operations

#### Issue Back Token (`emitBack` in `TradingLib.sol`)

- **Example**:
  Issuing 1 Back A token (as in Overview section 4a).

- **Accounting**:
  - `tilt[mmId][marketId][A] -= amount` 
    reducing available shares for position A.

- **Solvency Enforcement**:
  Calls `ensureSolvency`,
  which checks `minShares = minTilt + AllocatedCapital[mmId][marketId]`.
  If `minShares < 0`,
  allocates from `freeCollateral` to `AllocatedCapital`
  to make `minShares >= 0`.



#### Receive Back Token (`receiveBackToken` in `TradingLib.sol`)

- **Example**:
  Receiving 1 Back A token (as in Overview section 4b).

- **Accounting**:
  - `tilt[mmId][marketId][A] += amount` 
    increasing available shares for position A.

- **Solvency Enforcement**:
  Calls `deallocateExcess`,
  which checks if `AllocatedCapital[mmId][marketId] + minTilt > 0`.
  If so, deallocates excess from `AllocatedCapital` back to `freeCollateral`.



### Lay Token Operations

#### Issue Lay Token (`emitLay` in `TradingLib.sol`)

- **Example**:
  Issuing 1 Lay A token (as in Overview section 4c).

- **Accounting**:
  - `tilt[mmId][marketId][i] += amount`
    for all positions \( i \neq A \) 
    increasing their available shares.
  - `AllocatedCapital[mmId][marketId] -= amount`
    reflecting the liability taken on.


- **Solvency Enforcement**:
  Calls `ensureSolvency`,
  checking `minShares = minTilt + AllocatedCapital[mmId][marketId]`.
  If `minShares < 0`,
  allocates from `freeCollateral` to `AllocatedCapital`.


#### Receive Lay Token (`receiveLayToken` in `TradingLib.sol`)

- **Example**:
  Receiving 1 Lay A token (as in Overview section 4d).

- **Accounting**:
  - `tilt[mmId][marketId][i] -= amount`
    for all positions \( i \neq A \) 
    decreasing their available shares.
  - `AllocatedCapital[mmId][marketId] += amount` 
    reflecting the return of liability.


- **Solvency Enforcement**:
  Calls `deallocateExcess`,
  deallocating excess if `AllocatedCapital[mmId][marketId] + minTilt > 0`.


### USDC Operations

#### Receive USDC (`processBuy` in `TradingLib.sol`)

- **Example**:
  Receiving 1 USDC (as in Overview section 4e).

- **Accounting**:
  - `freeCollateral[mmId] += amount` 
    increasing available shares for all positions.


#### Emit USDC (`processSell` in `TradingLib.sol`)

- **Example**:
  Emitting 1 USDC (as in Overview section 4f).

- **Accounting**:
  - `freeCollateral[mmId] -= amount` 
    decreasing available shares for all positions.

- **Check**:
  Ensures `freeCollateral[mmId] >= amount` (via `DepositWithdrawLib.withdrawTo`),
  keeping `freeCollateral` non-negative.
