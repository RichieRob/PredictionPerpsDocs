# Ledger Accounting

This document details the internal accounting of the ledger,
specifically how `freeCollateral`, `AllocatedCapital`, and `tilt` are updated
to manage Back and Lay token operations,
as implemented in the provided Solidity contracts.
It assumes familiarity with the [LedgerOverview](LedgerOverview.md)
and focuses solely on the accounting mechanics for these operations.

## Innovation

The ledger's accounting revolutionizes liquidity provision by unifying the market maker's supplied liquitidy.
 
This unlocks unparalleled flexibility in providing liquidity within and across multi-position markets simultaneously from a singular deposit.

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


## Worked Examples 

These examples show, step by step, how the ledger updates `freeCollateral`, `AllocatedCapital`, and `tilt` through Back, Lay, and USDC operations.

Each step follows this format:

1. **Token Change** – the direct change to `tilt` or `AllocatedCapital`
2. **Solvency Check** – compute `minTilt` and `minShares = AllocatedCapital + minTilt`
3. **Solvency Action** – minimal reallocation to bring `minShares` back to 0
4. **Result** – new ledger state after adjustments

All examples are cumulative, beginning with 100 USDC and positions **A**, **B**, **C**, **D**.  
Available shares:  
\\[
H_k = \text{freeCollateral} + \text{AllocatedCapital} + \text{tilt}[k]
\\]

---

### Initial State

| Variable | Value |
|-----------|------:|
| freeCollateral | 100 |
| AllocatedCapital | 0 |
| tilt[A] | 0 |
| tilt[B] | 0 |
| tilt[C] | 0 |
| tilt[D] | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 100 | 100 + 0 + 0 |
| B | 100 | 100 + 0 + 0 |
| C | 100 | 100 + 0 + 0 |
| D | 100 | 100 + 0 + 0 |

---

#### 1 · Issue Back A (amount = 10)

##### Token Change
- `tilt[A] -= 10`

##### Solvency Check 
- `minTilt = −10` (A is min)  
- `minShares = AllocatedCapital + minTilt = 0 + (−10) = −10`  

##### Solvency Action
- reallocate to set `minShares = 0`
- allocate `10` from `freeCollateral` → `AllocatedCapital`

##### Result
- `freeCollateral = 90`
- `AllocatedCapital = 10`
- `tilt[A] = −10`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 100 | 0 | −10 | 90 |
| AllocatedCapital | 0 | 0 | +10 | 10 |
| tilt[A] | 0 | −10 | 0 | −10 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 90 | 90 + 10 − 10 |
| B | 100 | 90 + 10 + 0 |
| C | 100 | 90 + 10 + 0 |
| D | 100 | 90 + 10 + 0 |

---

#### 2 · Receive Back A (amount = 4)

##### Token Change
- `tilt[A] += 4` → −6

##### Solvency Check 
- `minTilt = −6`  
- `minShares = AllocatedCapital + minTilt = 10 + (−6) = 4`  

##### Solvency Action
- reallocate to set `minShares = 0`
- deallocate `4` from `AllocatedCapital` → `freeCollateral`

##### Result
- `freeCollateral = 94`
- `AllocatedCapital = 6`
- `tilt[A] = −6`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 90 | 0 | +4 | 94 |
| AllocatedCapital | 10 | 0 | −4 | 6 |
| tilt[A] | −10 | +4 | 0 | −6 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 94 | 94 + 6 − 6 |
| B | 100 | 94 + 6 + 0 |
| C | 100 | 94 + 6 + 0 |
| D | 100 | 94 + 6 + 0 |

---

#### 3 · Issue Lay A (amount = 8)

##### Token Change
- `AllocatedCapital -= 8` → 6 → −2  
- `tilt[A] += 8` → −6 → +2

##### Solvency Check 
- `minTilt = 0`  
- `minShares = (−2) + 0 = −2`

##### Solvency Action
- allocate `2` from `freeCollateral` → `AllocatedCapital`

##### Result
- `freeCollateral = 92`
- `AllocatedCapital = 0`
- `tilt[A] = +2`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 94 | 0 | −2 | 92 |
| AllocatedCapital | 6 | −8 | +2 | 0 |
| tilt[A] | −6 | +8 | 0 | +2 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 94 | 92 + 0 + 2 |
| B | 92 | 92 + 0 + 0 |
| C | 92 | 92 + 0 + 0 |
| D | 92 | 92 + 0 + 0 |

---

#### 4 · Receive Lay A (amount = 3)

##### Token Change
- `AllocatedCapital += 3` → 0 → 3  
- `tilt[A] -= 3` → +2 → −1

##### Solvency Check 
- `minTilt = −1`  
- `minShares = 3 + (−1) = 2`

##### Solvency Action
- deallocate `2` from `AllocatedCapital` → `freeCollateral`

##### Result
- `freeCollateral = 94`
- `AllocatedCapital = 1`
- `tilt[A] = −1`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 92 | 0 | +2 | 94 |
| AllocatedCapital | 0 | +3 | −2 | 1 |
| tilt[A] | +2 | −3 | 0 | −1 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 94 | 94 + 1 − 1 |
| B | 95 | 94 + 1 + 0 |
| C | 95 | 94 + 1 + 0 |
| D | 95 | 94 + 1 + 0 |

---

#### 5 · Receive USDC (amount = 12)

##### Token Change
- `freeCollateral += 12` → 94 → 106

##### Solvency Check 
- `minTilt = −1`, `minShares = 1 + (−1) = 0`

##### Solvency Action
- no movement required

##### Result
- `freeCollateral = 106`
- `AllocatedCapital = 1`
- `tilt[A] = −1`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 94 | +12 | 0 | 106 |
| AllocatedCapital | 1 | 0 | 0 | 1 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 106 | 106 + 1 − 1 |
| B | 107 | 106 + 1 + 0 |
| C | 107 | 106 + 1 + 0 |
| D | 107 | 106 + 1 + 0 |

---

#### 6 · Emit USDC (amount = 7)

##### Token Change
- `freeCollateral -= 7` → 106 → 99

##### Solvency Check 
- `minTilt = −1`, `minShares = 1 + (−1) = 0`

##### Solvency Action
- no movement required

##### Result
- `freeCollateral = 99`
- `AllocatedCapital = 1`
- `tilt[A] = −1`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 106 | −7 | 0 | 99 |
| AllocatedCapital | 1 | 0 | 0 | 1 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | 0 | 0 | 0 | 0 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 99 | 99 + 1 − 1 |
| B | 100 | 99 + 1 + 0 |
| C | 100 | 99 + 1 + 0 |
| D | 100 | 99 + 1 + 0 |

---

#### 7 · Issue Back B (amount = 5)

##### Token Change
- `tilt[B] -= 5`

##### Solvency Check 
- `minTilt = −5`  
- `minShares = 1 + (−5) = −4`

##### Solvency Action
- allocate `4` from `freeCollateral` → `AllocatedCapital`

##### Result
- `freeCollateral = 95`
- `AllocatedCapital = 5`
- `tilt[B] = −5`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 99 | 0 | −4 | 95 |
| AllocatedCapital | 1 | 0 | +4 | 5 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | 0 | −5 | 0 | −5 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 99 | 95 + 5 − 1 |
| B | 95 | 95 + 5 − 5 |
| C | 100 | 95 + 5 + 0 |
| D | 100 | 95 + 5 + 0 |

---

#### 8 · Receive Back B (amount = 2)

##### Token Change
- `tilt[B] += 2` → −3

##### Solvency Check 
- `minTilt = −3`  
- `minShares = 5 + (−3) = 2`

##### Solvency Action
- deallocate `2` from `AllocatedCapital` → `freeCollateral`

##### Result
- `freeCollateral = 97`
- `AllocatedCapital = 3`
- `tilt[B] = −3`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 95 | 0 | +2 | 97 |
| AllocatedCapital | 5 | 0 | −2 | 3 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | −5 | +2 | 0 | −3 |
| tilt[C] | 0 | 0 | 0 | 0 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 99 | 97 + 3 − 1 |
| B | 97 | 97 + 3 − 3 |
| C | 100 | 97 + 3 + 0 |
| D | 100 | 97 + 3 + 0 |

---

#### 9 · Issue Lay C (amount = 6)

##### Token Change
- `AllocatedCapital -= 6` → 3 → −3  
- `tilt[C] += 6`

##### Solvency Check 
- `minTilt = −3`  
- `minShares = (−3) + (−3) = −6`

##### Solvency Action
- allocate `6` from `freeCollateral` → `AllocatedCapital`

##### Result
- `freeCollateral = 91`
- `AllocatedCapital = 3`
- `tilt[C] = +6`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 97 | 0 | −6 | 91 |
| AllocatedCapital | 3 | −6 | +6 | 3 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | −3 | 0 | 0 | −3 |
| tilt[C] | 0 | +6 | 0 | +6 |
| tilt[D] | 0 | 0 | 0 | 0 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 93 | 91 + 3 − 1 |
| B | 91 | 91 + 3 − 3 |
| C | 100 | 91 + 3 + 6 |
| D | 94 | 91 + 3 + 0 |

---

#### 10 · Receive Lay D (amount = 3)

##### Token Change
- `AllocatedCapital += 3` → 3 → 6  
- `tilt[D] -= 3`

##### Solvency Check 
- `minTilt = −3`  
- `minShares = 6 + (−3) = 3`

##### Solvency Action
- deallocate `3` from `AllocatedCapital` → `freeCollateral`

##### Result
- `freeCollateral = 94`
- `AllocatedCapital = 3`
- `tilt[D] = −3`

| Variable | Before | Δ (token) | Δ (solvency) | After |
|---|---:|---:|---:|---:|
| freeCollateral | 91 | 0 | +3 | 94 |
| AllocatedCapital | 3 | +3 | −3 | 3 |
| tilt[A] | −1 | 0 | 0 | −1 |
| tilt[B] | −3 | 0 | 0 | −3 |
| tilt[C] | +6 | 0 | 0 | +6 |
| tilt[D] | 0 | −3 | 0 | −3 |

| Pos | Hₖ | Formula |
|-----|----:|----------|
| A | 96 | 94 + 3 − 1 |
| B | 94 | 94 + 3 − 3 |
| C | 103 | 94 + 3 + 6 |
| D | 94 | 94 + 3 − 3 |

---

### Notes

- **minShares = AllocatedCapital + minTilt** is the solvency gauge.
- If `minShares < 0`: allocate from `freeCollateral` → `AllocatedCapital`.  
- If `minShares > 0`: deallocate from `AllocatedCapital` → `freeCollateral`.  
- **Back k:** adjusts only `tilt[k]`.  
- **Lay k:** adjusts both `tilt[k]` and `AllocatedCapital`.  
- **USDC:** affects only `freeCollateral`.  
- Reallocation always minimally restores `minShares = 0` without overcorrecting.
