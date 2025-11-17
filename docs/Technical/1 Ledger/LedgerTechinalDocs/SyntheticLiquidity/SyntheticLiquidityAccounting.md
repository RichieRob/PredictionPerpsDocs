---
comments: true
slug: synthetic-liquidity-accounting  # Stable ID, e.g., for linking as /what-is-it/
title: Synthetic Liquidity Accounting  # Optional display title
---

# Synthetic Liquidity Accounting

This document details the internal accounting of the ledger, including the addition of the synthetic Liquidity,
specifically how `freeCollateral`, `USDCSpent`, `layOffset`, and `tilt` are updated
to manage Back and Lay token operations,
as implemented in the provided Solidity contracts.
It assumes familiarity with the [**LedgerOverview**](LedgerOverview.md)
and focuses solely on the accounting mechanics for these operations.

## Innovation

The ledger's accounting revolutionizes liquidity provision by unifying the market maker's supplied liquidity.
 
This unlocks unparalleled flexibility in providing liquidity within and across multi-position markets simultaneously from a singular deposit.

With synthetic liquidity (ISC), markets bootstrap with virtual depth for the designated market maker (DMM), allowing immediate trading. ISC acts as collateral in calculations but is replaced by real inflows over time, with profits unlocked only when fully refilled (no ISC drawn).

## Accounting Components

The ledger uses four variables in `StorageLib.sol` 
to track the market maker's (MM) balance
for each market (`marketId`) and position (`positionId`):

- **Free Collateral**: `mapping(uint256 => uint256) freeCollateral`
  tracks unallocated USDC for an MM (`mmId`),
  representing liquid capital.

- **USDC Spent**: `mapping(uint256 => mapping(uint256 => int256)) USDCSpent`
  tracks the net USDC committed to a market.
  Positive values indicate USDC deposited;
  negative values indicate profit received (only allowed when ISC is refilled for DMM).

- **Lay Offset**: `mapping(uint256 => mapping(uint256 => int256)) layOffset`
  tracks the net Lay token flow for a market.
  Positive values indicate Lay received;
  negative values indicate Lay issued.

- **Tilt**: `mapping(uint256 => mapping(uint256 => mapping(uint256 => int128)) tilt`
  adjusts the available shares for a specific position.
  Positive `tilt` increases available shares;
  negative `tilt` decreases them.

- **ISC**: `mapping(uint256 => uint256) syntheticCollateral`
  represents synthetic initial seed capital (ISC) for designated market makers (DMMs).
  ISC is virtually added to freeCollateral in views and solvency checks,
  acting like real USDC for trading depth but not redeemable until replaced by real inflows.

For DMMs, **ISC** (syntheticCollateral[marketId]) is virtually added to freeCollateral in views and solvency, acting like real USDC for trading depth.

The available shares for a position \( k \), denoted \( H_k \), are:

\[
H_k = \text{freeCollateral}[\text{mmId}] + (\text{if DMM then ISC else 0}) + \text{USDCSpent}[\text{mmId}][\text{marketId}] + \text{layOffset}[\text{mmId}][\text{marketId}] + \text{tilt}[\text{mmId}][\text{marketId}][k]
\]

## Accounting for Back and Lay Tokens

The ledger updates `freeCollateral`, `USDCSpent`, `layOffset`, and `tilt`
in `TradingLib.sol`
to reflect the issuance and receipt of Back and Lay tokens,
matching the operations in the Ledger Overview.
Solvency enforcement via `SolvencyLib.sol`
is applied after token operations
to ensure effective \( H_k \geq 0 \), with real backing for redeemables.

### Back Token Operations

#### Issue Back Token (`emitBack` in `TradingLib.sol`)

- **Example**:
  Issuing 1 Back A token (as in Overview section 4a).

- **Accounting**:
  - `tilt[mmId][marketId][A] -= amount` 
    reducing available shares for position A.

- **Solvency Enforcement**:
  Calls `ensureSolvency`,
  which computes real_minShares = minTilt + USDCSpent + layOffset,
  effective_minShares = real_minShares + (DMM ? ISC : 0).
  If effective_minShares < 0,
  allocates real from `freeCollateral` to `USDCSpent`.
  Also checks redeemable = -layOffset - maxTilt;
  if >0 and USDCSpent < redeemable, allocates real difference (revert if insufficient).



#### Receive Back Token (`receiveBackToken` in `TradingLib.sol`)

- **Example**:
  Receiving 1 Back A token (as in Overview section 4b).

- **Accounting**:
  - `tilt[mmId][marketId][A] += amount` 
    increasing available shares for position A.

- **Solvency Enforcement**:
  Calls `deallocateExcess`,
  which computes effective_minShares.
  If >0, deallocates excess from `USDCSpent` to `freeCollateral`,
  but caps for redeemable (keep USDCSpent >= redeemable if >0)
  and for DMM if real_minShares <0 (prevent negative USDCSpent).



### Lay Token Operations

#### Issue Lay Token (`emitLay` in `TradingLib.sol`)

- **Example**:
  Issuing 1 Lay A token (as in Overview section 4c).

- **Accounting**:
  - `layOffset[mmId][marketId] -= amount` 
    reflecting the liability taken on.
  - `tilt[mmId][marketId][A] += amount` 
    increasing available shares for position A.


- **Solvency Enforcement**:
  Calls `ensureSolvency`,
  updating effective_minShares.
  Allocates real if effective_minShares <0.
  Checks/allocates for redeemable if needed (revert if insufficient).


#### Receive Lay Token (`receiveLayToken` in `TradingLib.sol`)

- **Example**:
  Receiving 1 Lay A token (as in Overview section 4d).

- **Accounting**:
  - `layOffset[mmId][marketId] += amount` 
    reflecting the return of liability.
  - `tilt[mmId][marketId][A] -= amount` 
    decreasing available shares for position A.


- **Solvency Enforcement**:
  Calls `deallocateExcess`,
  deallocating excess if effective_minShares >0,
  with caps for redeemable and (for DMM) if real_minShares <0.


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


## Worked Examples 

These examples show, step by step, how the ledger updates `freeCollateral`, `USDCSpent`, `layOffset`, and `tilt` through Back, Lay, and USDC operations.

Each step follows this format:

1. **Token Change** – the direct change to `tilt` or `layOffset` or `USDCSpent`
2. **Solvency Check** – compute `minTilt`, real_minShares = USDCSpent + layOffset + minTilt, effective_minShares = real_minShares + ISC (for DMM), redeemable = -layOffset - maxTilt
3. **Solvency Action** – allocate real if effective_minShares <0 or USDCSpent < redeemable (>0); deallocate with caps if effective_minShares >0
4. **Result** – new ledger state after adjustments

All examples are cumulative, beginning with ISC=100 (DMM), 0 real USDC, positions **A**, **B**, **C**, **D**.  
Available shares:  
\\[
H_k = \text{freeCollateral} + \text{ISC} + \text{USDCSpent} + \text{layOffset} + \text{tilt}[k]
\\]

---

// ADD ISC TO THESE TABLES FOR ALL EXAMPLES!


### Initial State

// ADD ISC TO THese TABLE

| Variable | Value |
|-----------|------:|
| freeCollateral | 0 |
| ISC | 100 |
| USDCSpent | 0 |
| layOffset | 0 |
| tilt[A] | 0 |
| tilt[B] | 0 |
| tilt[C] | 0 |
| tilt[D] | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 100 | 0 + 100 + 0 + 0 + 0 |
| B | 100 | 0 + 100 + 0 + 0 + 0 |
| C | 100 | 0 + 100 + 0 + 0 + 0 |
| D | 100 | 0 + 100 + 0 + 0 + 0 |

---

#### 1 · Issue Back A (amount = 10)

##### Token Change
- `tilt[A] -= 10`

##### Solvency Check 
- `minTilt = −10`, maxTilt = 0  
- real_minShares = 0 + 0 + (−10) = −10  
- effective_minShares = −10 + 100 = 90  
- redeemable = 0 - 0 = 0  

##### Solvency Action
- no allocation (effective >=0); no redeemable alloc

##### Result
- `freeCollateral = 0`
- `USDCSpent = 0`
- `layOffset = 0`
- `tilt[A] = −10`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 0 | 0 | 0 | 0 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 0 | 0 | 0 | 0 |
| layOffset | 0 | 0 | 0 | 0 |
| tilt[A] | 0 | −10 | 0 | −10 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 90 | 0 + 100 + 0 + 0 − 10 |
| B | 100 | 0 + 100 + 0 + 0 + 0 |
| C | 100 | 0 + 100 + 0 + 0 + 0 |
| D | 100 | 0 + 100 + 0 + 0 + 0 |

---

#### 2 · Receive USDC (amount = 20)

##### Token Change
- `freeCollateral += 20` → 0 → 20

##### Solvency Check 
- `minTilt = −10`, maxTilt = 0  
- real_minShares = 0 + 0 + (−10) = −10  
- effective_minShares = −10 + 100 = 90  
- redeemable = 0 - 0 = 0  

##### Solvency Action
- no action (effective >0, but no dealloc on receive USDC)

##### Result
- `freeCollateral = 20`
- `USDCSpent = 0`
- `layOffset = 0`
- `tilt[A] = −10`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 0 | +20 | 0 | 20 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 0 | 0 | 0 | 0 |
| layOffset | 0 | 0 | 0 | 0 |
| tilt[A] | −10 | 0 | 0 | −10 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 110 | 20 + 100 + 0 + 0 − 10 |
| B | 120 | 20 + 100 + 0 + 0 + 0 |
| C | 120 | 20 + 100 + 0 + 0 + 0 |
| D | 120 | 20 + 100 + 0 + 0 + 0 |

---

#### 3 · Issue Back A (amount = 110)

##### Token Change
- `tilt[A] -= 110` → −120

##### Solvency Check 
- `minTilt = −120`, maxTilt = 0  
- real_minShares = 0 + 0 + (−120) = −120  
- effective_minShares = −120 + 100 = −20  
- redeemable = 0 - 0 = 0  

##### Solvency Action
- allocate 20 real to USDCSpent (from freeCollateral)

##### Result
- `freeCollateral = 0`
- `USDCSpent = 20`
- `layOffset = 0`
- `tilt[A] = −120`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 20 | 0 | −20 | 0 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 0 | 0 | +20 | 20 |
| layOffset | 0 | 0 | 0 | 0 |
| tilt[A] | −10 | −110 | 0 | −120 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 0 | 0 + 100 + 20 + 0 − 120 |
| B | 120 | 0 + 100 + 20 + 0 + 0 |
| C | 120 | 0 + 100 + 20 + 0 + 0 |
| D | 120 | 0 + 100 + 20 + 0 + 0 |

---

#### 4 · Receive Back A (amount = 50)

##### Token Change
- `tilt[A] += 50` → −70

##### Solvency Check 
- `minTilt = −70`, maxTilt = 0  
- real_minShares = 20 + 0 + (−70) = −50  
- effective_minShares = −50 + 100 = 50  
- redeemable = 0 - 0 = 0  

##### Solvency Action
- deallocate 50, but since real_minShares <0, cap to USDCSpent=20 (keep >=0); dealloc 20

##### Result
- `freeCollateral = 20`
- `USDCSpent = 0`
- `layOffset = 0`
- `tilt[A] = −70`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 0 | 0 | +20 | 20 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 20 | 0 | −20 | 0 |
| layOffset | 0 | 0 | 0 | 0 |
| tilt[A] | −120 | +50 | 0 | −70 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 50 | 20 + 100 + 0 + 0 − 70 |
| B | 120 | 20 + 100 + 0 + 0 + 0 |
| C | 120 | 20 + 100 + 0 + 0 + 0 |
| D | 120 | 20 + 100 + 0 + 0 + 0 |

---

#### 5 · Issue Lay B (amount = 30)

##### Token Change
- `layOffset -= 30` → 0 → −30  
- `tilt[B] += 30`

##### Solvency Check 
- `minTilt = −70` (A), maxTilt = 30 (B)  
- real_minShares = 0 + (−30) + (−70) = −100  
- effective_minShares = −100 + 100 = 0  
- redeemable = - (−30) - 30 = 0  

##### Solvency Action
- no alloc (effective =0); no redeemable alloc

##### Result
- `freeCollateral = 20`
- `USDCSpent = 0`
- `layOffset = −30`
- `tilt[B] = 30`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 20 | 0 | 0 | 20 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 0 | 0 | 0 | 0 |
| layOffset | 0 | −30 | 0 | −30 |
| tilt[A] | −70 | 0 | 0 | −70 |
| tilt[B] | 0 | +30 | 0 | 30 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 20 | 20 + 100 + 0 + (−30) − 70 |
| B | 120 | 20 + 100 + 0 + (−30) + 30 |
| C | 90 | 20 + 100 + 0 + (−30) + 0 |
| D | 90 | 20 + 100 + 0 + (−30) + 0 |

---

#### 6 · Receive Lay B (amount = 10)

##### Token Change
- `layOffset += 10` → −30 → −20  
- `tilt[B] -= 10` → 20

##### Solvency Check 
- `minTilt = −70`, maxTilt = 20  
- real_minShares = 0 + (−20) + (−70) = −90  
- effective_minShares = −90 + 100 = 10  
- redeemable = - (−20) - 20 = 0  

##### Solvency Action
- deallocate 10, but since real_minShares <0, cap to USDCSpent=0 (dealloc 0)

##### Result
- `freeCollateral = 20`
- `USDCSpent = 0`
- `layOffset = −20`
- `tilt[B] = 20`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---| ---:|---:|---:|---:|
| freeCollateral | 20 | 0 | 0 | 20 |
| ISC | 100 | 0 | 0 | 100 |
| USDCSpent | 0 | 0 | 0 | 0 |
| layOffset | −30 | +10 | 0 | −20 |
| tilt[A] | −70 | 0 | 0 | −70 |
| tilt[B] | 30 | −10 | 0 | 20 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 10 | 20 + 100 + 0 + (−20) − 70 |
| B | 120 | 20 + 100 + 0 + (−20) + 20 |
| C | 100 | 20 + 100 + 0 + (−20) + 0 |
| D | 100 | 20 + 100 + 0 + (−20) + 0 |

---

### Notes

- effective_minShares = real_minShares + ISC (DMM) is the solvency gauge for trading.
- If effective_minShares < 0: allocate real from `freeCollateral` → `USDCSpent`.  
- If effective_minShares > 0: deallocate from `USDCSpent` → `freeCollateral`, with caps for redeemable (USDCSpent >= redeemable) and DMM profits (if real_minShares <0, no negative USDCSpent).  
- redeemable = -layOffset - maxTilt; allocate real if USDCSpent < redeemable (>0).  
- **Back k:** adjusts only `tilt[k]`.  
- **Lay k:** adjusts `layOffset` and `tilt[k]`.  
- **USDC:** affects only `freeCollateral`.  
- Reallocation restores effective_minShares = 0 minimally; redeemable enforced independently.

## Further Reading
To see the implementation of these accounting principles in code see [**Ledger.sol**](../../../Contracts/Ledger.sol.md) and accompanying libraries.

--8<-- "link-refs.md"
