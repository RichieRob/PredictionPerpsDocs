---
title: Ledger Invariant Views — Prototype
slug: ledger-invariant-views
description: Helper view functions for asserting ledger invariants in the 1‑MM, 1‑market prototype.
---

# Ledger Invariant Views — Prototype

This document defines **clean, complete invariant‑checking views** for the Ledger prototype.  
Each invariant corresponds to a pure/view helper in `LedgerInvariantViews.sol`, with optional external wrappers on `MarketMakerLedger.sol`.

---

## 1 · Invariant → Helper Map

| Invariant                                                   | Helper (library)                          | Optional wrapper on `MarketMakerLedger`             |
|-------------------------------------------------------------|-------------------------------------------|-----------------------------------------------------|
| `marketValue == MarketUSDCSpent - Redemptions`              | `marketAccounting(marketId)`              | `invariant_marketAccounting(marketId)`             |
| `effMin >= 0`                                               | `effectiveMinShares(mmId, marketId)`      | `invariant_effectiveMin(mmId, marketId)`           |
| `iscSpent <= syntheticCollateral`                           | `iscSpent(marketId)`                      | `invariant_iscWithinLine(marketId)`                |
| `E_i == E_j` (balanced exposure across outcomes)            | `exposureForPosition`, `checkBalancedExposure` | `invariant_balancedExposure`                |
| `E = marketValue + iscSpent`                                | `totalFullSets`                           | `invariant_systemFunding`                          |
| `fullSetsUser <= E`                                         | `fullSetsUser`, `checkUserFundingInvariant` | `invariant_userFunding`                          |

---

# 2 · Market Accounting

```
marketValue = MarketUSDCSpent − Redemptions
```

### 2.1 Library helper

```solidity
function marketAccounting(uint256 marketId)
    internal
    view
    returns (uint256 lhs, uint256 rhs)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    lhs = s.marketValue[marketId];
    rhs = s.MarketUSDCSpent[marketId] - s.Redemptions[marketId];
}
```

### 2.2 Wrapper

```solidity
function invariant_marketAccounting(uint256 marketId)
    external view
    returns (uint256 lhs, uint256 rhs)
{
    return LedgerInvariantViews.marketAccounting(marketId);
}
```

---

# 3 · Synthetic Liquidity Usage (iscSpent)

```
realMinShares = netUSDCAllocation + layOffset + minTilt
iscSpent      = max(0, -realMinShares)
```

### 3.1 Library helper

```solidity
function iscSpent(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();

    uint256 dmmId = s.marketToDMM[marketId];
    int256 realMin = SolvencyLib.computeRealMinShares(s, dmmId, marketId);
    if (realMin >= 0) return 0;
    return uint256(-realMin);
}
```

### 3.2 Wrapper

```solidity
function invariant_iscWithinLine(uint256 marketId)
    external
    view
    returns (uint256 used, uint256 line)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    used = LedgerInvariantViews.iscSpent(marketId);
    line = s.syntheticCollateral[marketId];
}
```

---

# 4 · Effective Minimum Shares (effMin)

```
effMin = realMinShares + syntheticCollateral
effMin must be >= 0
```

### 4.1 Library helper

```solidity
function effectiveMinShares(uint256 mmId, uint256 marketId)
    internal
    view
    returns (int256 effMin)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    int256 realMin = SolvencyLib.computeRealMinShares(s, mmId, marketId);
    effMin = SolvencyLib.computeEffectiveMinShares(s, mmId, marketId, realMin);
}
```

### 4.2 Wrapper

```solidity
function invariant_effectiveMin(uint256 mmId, uint256 marketId)
    external view
    returns (int256 effMin)
{
    return LedgerInvariantViews.effectiveMinShares(mmId, marketId);
}
```

---

# 5 · System Funding: totalFullSets = marketValue + iscSpent

### 5.1 Library helper

```solidity
function totalFullSets(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 mv  = s.marketValue[marketId];
    uint256 isc = iscSpent(marketId);
    return mv + isc;
}
```

### 5.2 Wrapper

```solidity
function invariant_systemFunding(uint256 marketId)
    external view
    returns (uint256 fullSetsSystem)
{
    return LedgerInvariantViews.totalFullSets(marketId);
}
```

---

# 6 · User Full Sets: fullSetsUser ≤ E

### 6.1 Library helpers

```solidity
function backSupply(uint256 marketId, uint256 positionId)
    internal view returns (uint256)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 id = StorageLib.encodeTokenId(
        uint64(marketId),
        uint64(positionId),
        true
    );
    return IPositionToken1155(s.positionToken1155).totalSupply(id);
}

function laySupply(uint256 marketId, uint256 positionId)
    internal view returns (uint256)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 id = StorageLib.encodeTokenId(
        uint64(marketId),
        uint64(positionId),
        false
    );
    return IPositionToken1155(s.positionToken1155).totalSupply(id);
}

function fullSetsUser(uint256 marketId) internal view returns (uint256) {
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256[] storage pos = s.marketPositions[marketId];

    if (pos.length == 0) return 0;

    uint256 minB = type(uint256).max;
    for (uint256 i = 0; i < pos.length; i++) {
        uint256 B = backSupply(marketId, pos[i]);
        if (B < minB) minB = B;
    }
    return (minB == type(uint256).max) ? 0 : minB;
}
```

### 6.2 Combined invariant

```solidity
function checkUserFundingInvariant(uint256 marketId)
    internal view
    returns (bool ok, uint256 fullUser, uint256 fullSystem)
{
    fullUser   = fullSetsUser(marketId);
    fullSystem = totalFullSets(marketId);
    ok = (fullUser <= fullSystem);
}
```

### 6.3 Wrapper

```solidity
function invariant_userFunding(uint256 marketId)
    external view
    returns (bool ok, uint256 fullUser, uint256 fullSystem)
{
    return LedgerInvariantViews.checkUserFundingInvariant(marketId);
}
```

---

# 7 · Balanced Exposure Across Outcomes

We require:

```
E_i == E_j   for all positions i, j
```

Where:

```
UserExposure_i = Back_i + Σ (Lay_j for j ≠ i)

mmExposure_i = netUSDCAllocation + iscSpent + layOffset + tilt[i]

E_i = UserExposure_i + mmExposure_i
```

### 7.1 User exposure

```solidity
function userExposure(uint256 marketId, uint256 positionId)
    internal view returns (int256)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256[] storage pos = s.marketPositions[marketId];

    uint256 B = backSupply(marketId, positionId);

    uint256 L_not_i = 0;
    for (uint256 i = 0; i < pos.length; i++) {
        uint256 pid = pos[i];
        if (pid == positionId) continue;
        L_not_i += laySupply(marketId, pid);
    }

    return int256(B + L_not_i);
}
```

### 7.2 Total exposure per position

```solidity
function exposureForPosition(uint256 marketId, uint256 positionId)
    internal view returns (int256)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    uint256 dmmId = s.marketToDMM[marketId];

    int256 userExp = userExposure(marketId, positionId);
    int256 netAlloc = SolvencyLib._netUSDCAllocationSigned(s, dmmId, marketId);
    int256 base = netAlloc + s.layOffset[dmmId][marketId];

    uint256 isc  = iscSpent(marketId);
    int256 tilt  = int256(s.tilt[dmmId][marketId][positionId]);

    return userExp + base + int256(isc) + tilt;
}
```

### 7.3 Check all equal

```solidity
function checkBalancedExposure(uint256 marketId)
    internal view
    returns (bool ok, int256 reference, uint256[] memory posOut)
{
    StorageLib.Storage storage s = StorageLib.getStorage();
    posOut = s.marketPositions[marketId];

    if (posOut.length == 0) return (true, 0, posOut);

    reference = exposureForPosition(marketId, posOut[0]);

    for (uint256 i = 1; i < posOut.length; i++) {
        int256 Ei = exposureForPosition(marketId, posOut[i]);
        if (Ei != reference) return (false, reference, posOut);
    }
    return (true, reference, posOut);
}
```

### 7.4 Wrapper

```solidity
function invariant_balancedExposure(uint256 marketId)
    external view
    returns (bool ok, int256 ref, uint256[] memory pos)
{
    return LedgerInvariantViews.checkBalancedExposure(marketId);
}
```

---

# 8 · Test Helper

```solidity
function assertAllInvariants() internal {
    (uint a, uint b) = ledger.invariant_marketAccounting(0);
    assertEq(a, b, "market accounting");

    (uint used, uint line) = ledger.invariant_iscWithinLine(0);
    assertLe(used, line, "isc > line");

    int256 effMin = ledger.invariant_effectiveMin(0, 0);
    assertGe(effMin, 0, "effMin < 0");

    (bool okUser,,) = ledger.invariant_userFunding(0);
    assertTrue(okUser, "fullSetsUser > E");

    (bool okExp,,) = ledger.invariant_balancedExposure(0);
    assertTrue(okExp, "E_i != E_j");
}
```

--8<-- "link-refs.md"
