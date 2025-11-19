---
comment: true
title: Prototype Ledger Invariants — Single MM, Single Market
slug: prototype-invariants
description: Invariants and implementation plan for the first minimal ledger prototype with one Market Maker, one Market, and dummy Aave.
---

# Prototype Ledger Invariants  
### *(Single MM · Single Market · Dummy Aave · Synthetic Liquidity Enabled)*

This document specifies the **exact invariants** to implement and test in the **first ledger prototype**, where:

- There is **one** market maker (`mmId = 0`)
- There is **one** market (`marketId = 0`)
- The **single MM is the DMM** for this market
- Aave is replaced with a **1:1 dummy vault** (no interest)
- The ledger must enforce **balanced shares across all outcomes** (all \(E_i\) equal)
- Synthetic liquidity (ISC) is enabled for this market

This removes cross-MM and cross-market complexity and lets us fully lock down the core logic.

---

## 0 · Prototype Context & Simplifications

Because we have:

- 1 MM  
- 1 Market  
- 1 Synthetic liquidity line  
- Dummy Aave (no interest)

we get the following simplifications:

| Global Variable        | Prototype Meaning                                      |
|------------------------|--------------------------------------------------------|
| `marketValue`          | total real principal allocated to the market           |
| `freeCollateral`       | MM’s unallocated collateral                            |
| `totalFreeCollateral`  | same as `freeCollateral`                               |
| `totalValueLocked`     | `marketValue + freeCollateral`                         |
| `MarketUSDCSpent`      | real USDC sent into the market                        |
| `Redemptions`          | USDC withdrawn from the market via full-set redemption|
| `syntheticCollateral`  | ISC credit line for market 0                           |
| `marketToDMM`          | always maps to `mmId = 0`                              |

Thus:

```text
TotalMarketsValue == marketValue
totalFreeCollateral == freeCollateral
totalValueLocked == marketValue + freeCollateral
```

These become trivial invariants you can assert after every operation.

---

## 1 · Core Accounting Invariants (Prototype)

### 1.1 Non-negativity

All must remain ≥ 0:

- `freeCollateral`
- `totalFreeCollateral`
- `MarketUSDCSpent`
- `marketValue`
- `TotalMarketsValue`
- `totalValueLocked`
- `Redemptions`

---

### 1.2 Market value identity

```text
marketValue = MarketUSDCSpent - Redemptions
```

---

### 1.3 Global equalities

Since only one MM and one market:

```text
TotalMarketsValue == marketValue
totalFreeCollateral == freeCollateral
totalValueLocked == marketValue + freeCollateral
```

---

### 1.4 Aave dummy vault

Dummy Aave = 1:1 minting of aUSDC for USDC.

Invariant:

```text
aUSDC.balanceOf(ledger) == totalValueLocked
```

Always true unless ledger logic is wrong.

---

## 2 · Synthetic Liquidity Invariants (Prototype)

We define:

```text
iscSpent(marketId) = max(0, -realMin(DMM, marketId))
```

Where in the prototype:

```text
realMin = USDCSpent + layOffset + minTilt   // for mmId=0, marketId=0
```

### 2.1 ISC credit line is static

```text
syntheticCollateral[0] is immutable after market creation
```

### 2.2 ISC usage must not exceed line

```text
iscSpent(0) <= syntheticCollateral[0]
```

If this fails → **synthetic solvency violated**.

---

## 3 · Solvency Invariants (Prototype)

### 3.1 Effective min ≥ 0

Since this MM is the DMM:

```text
effMin = realMin + syntheticCollateral >= 0
```

### 3.2 Redeemable bounded by real allocation

```text
USDCSpent >= redeemable
```

Where:

```text
redeemable = -layOffset - maxTilt
```

### 3.3 deallocateExcess correctness

After `deallocateExcess`, further deallocation would violate:

- `effMin >= 0`, or
- `USDCSpent >= redeemable`, or
- `realMin >= -syntheticCollateral`

This ensures the MM never over-withdraws from a market.

---

## 4 · Token & Exposure Invariants  
### (Ledger-level · **must** hold in the prototype)

The ledger + token system must maintain **balanced exposure across all outcomes**, for the **entire system** (users + MM).

### 4.1 User exposure to outcome \(i\)

For a given outcome \(i\):

- A **Back(i)** token pays 1 if outcome \(i\) occurs.
- A **Lay(j)** token pays 1 if outcome \(j\) does **not** occur.  
  That means Lay(j) pays 1 for every outcome \(k \neq j\), including \(i\) whenever \(i \neq j\).

Let:

- \(B_i\) = total supply of Back(i) (all users)
- \(L_j\) = total supply of Lay(j) (all users)

Then users’ exposure to outcome \(i\) is:

\[
\text{UserExposure}_i
  = B_i + \sum_{j \neq i} L_j
\]

Equivalently, define:

\[
L_{\neg i} = \sum_{j \neq i} L_j
\]

and:

\[
\text{UserExposure}_i = B_i + L_{\neg i}
\]

This is **purely token-side**, no ledger variables.

---

### 4.2 MM exposure to outcome \(i\)

The MM’s exposure to outcome \(i\) lives in the ledger, not in ERC-1155 balances. In the prototype we treat it as:

```text
mmExposure_i = USDCSpent + iscSpent + layOffset + tilt[i]
```

Where:

- `USDCSpent` — MM’s real capital spent into the market
- `iscSpent` — how much of syntheticCollateral has been effectively drawn
- `layOffset` — net Lay flow for the market
- `tilt[i]` — per-position deviation from the baseline (redistributes exposure across outcomes)

This is **MM-side only**.

---

### 4.3 Total exposure per outcome \(E_i\)

System-wide exposure to outcome \(i\) (if outcome i happens, how many payoff units does the system owe?) is:

```text
E_i = UserExposure_i + mmExposure_i
```

i.e.

\[
E_i
  = \underbrace{B_i + \sum_{j \neq i} L_j}_{\text{users}}
    \;+\;
    \underbrace{\big(\text{USDCSpent} + \text{iscSpent} + \text{layOffset} + \text{tilt}[i]\big)}_{\text{MM}}
\]

The **ledger-level invariant** is:

```text
E_i == E_j  for all positions i, j
```

This is your “there is always someone taking the other side” rewritten at system level: the number of effective full sets in the system is **independent of which outcome you look at**.

---

### 4.4 Full sets = principal + synthetic

Let \(E\) denote the common value of all \(E_i\):

```text
E = E_0 = E_1 = ... = E_{N-1}
```

The system-wide full sets must satisfy:

\[
E = \text{marketValue} + \text{iscSpent}
\]

So:

```text
E = marketValue + iscSpent
```

This ties together:

- Real principal funding (`marketValue`)
- Synthetic principal usage (`iscSpent`)
- Token + MM exposure across outcomes.

---

### 4.5 user-side full sets

Users’ redeemable full sets depend only on Back tokens:

\[
fullSetsUser = \min_i B_i
\]

Invariant:

\[
fullSetsUser \le E
\]

i.e. users cannot hold more redeemable sets than the system is funded to cover (real + synthetic).

---

## 4.6 Implementing Section 4 in the Prototype

Below is how you can implement the Section 4 invariants in the current 1-MM, 1-market setup.

### 4.6.1 Compute Back and Lay token supplies \(B_i, L_j\)

In `LedgerTokenViews`:

```solidity
function backSupply(uint256 marketId, uint256 positionId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 backTokenId = StorageLib.encodeTokenId(
        uint64(marketId),
        uint64(positionId),
        true // isBack
    );
    return IPositionToken1155(s.positionToken1155).totalSupply(backTokenId);
}

function laySupply(uint256 marketId, uint256 positionId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 layTokenId = StorageLib.encodeTokenId(
        uint64(marketId),
        uint64(positionId),
        false // isBack = false
    );
    return IPositionToken1155(s.positionToken1155).totalSupply(layTokenId);
}
```

---

### 4.6.2 Compute userExposure(i)

```solidity
function userExposure(uint256 marketId, uint256 positionId) internal view returns (int256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256[] storage positions = s.marketPositions[marketId];

    // Back(i)
    uint256 B = backSupply(marketId, positionId);

    // Sum of Lay(j) for j != i
    uint256 L_not_i = 0;
    for (uint256 k = 0; k < positions.length; k++) {
        uint256 pid = positions[k];
        if (pid == positionId) continue;
        L_not_i += laySupply(marketId, pid);
    }

    return int256(B + L_not_i);
}
```

This is:

```text
UserExposure_i = B_i + sum_{j != i} L_j
```

---

### 4.6.3 Compute iscSpent

In `LedgerInvariantViews`:

```solidity
function iscSpent(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 dmmId = s.marketToDMM[marketId];

    int256 realMin = SolvencyLib.computeRealMinShares(s, dmmId, marketId);
    if (realMin >= 0) return 0;
    return uint256(-realMin);
}
```

And assert:

```solidity
assert(iscSpent(0) <= s.syntheticCollateral[0]);
```

---

### 4.6.4 Compute system full sets \(E\)

```solidity
function totalFullSets(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 mv  = s.marketValue[marketId];
    uint256 isc = iscSpent(marketId);
    return mv + isc;
}
```

So Section 4.4 is literally:

```solidity
uint256 E = totalFullSets(0);
```

---

### 4.6.5 Check user funding invariant

```solidity
function fullSetsUser(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256[] storage positions = s.marketPositions[marketId];
    require(positions.length > 0, "No positions");

    uint256 minB = type(uint256).max;
    for (uint256 i = 0; i < positions.length; i++) {
        uint256 B = backSupply(marketId, positions[i]);
        if (B < minB) {
            minB = B;
        }
    }
    return (minB == type(uint256).max) ? 0 : minB;
}

function checkUserFundingInvariant(uint256 marketId)
    internal
    view
    returns (bool ok, uint256 fullUser, uint256 fullSystem)
{
    fullUser   = fullSetsUser(marketId);
    fullSystem = totalFullSets(marketId);
    ok = (fullUser <= fullSystem);
}
```

In tests:

```solidity
(bool ok, uint256 fullUser, uint256 fullSystem) = LedgerInvariantViews.checkUserFundingInvariant(0);
assertTrue(ok);
```

---

### 4.6.6 Check **balanced exposure across outcomes**

You can expose a **view** that reconstructs \(E_i\) directly:

```solidity
function exposureForPosition(uint256 marketId, uint256 positionId) internal view returns (int256) {
    StorageLib.Storage storage s = StorageLib.getStorage();

    uint256 dmmId = s.marketToDMM[marketId];

    // User side: B_i + sum_{j != i} L_j
    int256 userExp = LedgerTokenViews.userExposure(marketId, positionId);

    // MM side baseline
    int256 base = s.USDCSpent[dmmId][marketId] + s.layOffset[dmmId][marketId];

    // Synthetic usage
    uint256 isc = iscSpent(marketId);

    // Per-position tilt
    int128 tilt = s.tilt[dmmId][marketId][positionId];

    // E_i = UserExposure_i + (USDCSpent + iscSpent + layOffset + tilt[i])
    return userExp + base + int256(uint256(isc)) + int256(tilt);
}
```

Then assert in tests:

```solidity
StorageLib.Storage storage s = StorageLib.getStorage();
uint256[] storage positions = s.marketPositions[0];

int256 ref = exposureForPosition(0, positions[0]);
for (uint256 i = 1; i < positions.length; i++) {
    assertEq(exposureForPosition(0, positions[i]), ref);
}
```

This is the **concrete implementation** of:

```text
USDCSpent + iscSpent + layOffset + tilt[i]
+ (Back_i + sum_{j != i} Lay_j)
is the same for each position across the market.
```

---

## 5 · Summary: Invariants to Test in Prototype

### Accounting

- `marketValue == MarketUSDCSpent - Redemptions`
- `totalFreeCollateral == freeCollateral`
- `TotalMarketsValue == marketValue`
- `totalValueLocked == marketValue + freeCollateral`
- `aUSDC.balanceOf(ledger) == totalValueLocked` (dummy Aave)
- All of the above are ≥ 0

### Solvency

- `effMin >= 0` (DMM)
- `redeemable <= USDCSpent`
- `iscSpent <= syntheticCollateral`

### Token ↔ Ledger Consistency

- **Balanced exposure across outcomes:**

  ```text
  exposureForPosition(i) == exposureForPosition(j)
  for all positions i, j
  ```

- **System exposure matches funding:**

  ```text
  E = totalFullSets(0) = marketValue + iscSpent
  ```

- **Users never exceed system funding:**

  ```text
  fullSetsUser <= E
  ```

These are your **minimum working invariants** for the prototype, in the simple 1-MM, 1-market, dummy-Aave world. They give you a very tight invariant harness without pulling in LMSR yet.

--8<-- "link-refs.md"
