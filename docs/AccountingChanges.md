THis refactor is implemented


# Refactor: Clean Ledger Accounting
### Top-Level Document – Minimal & Clear

---

## Goal

Make the accounting understandable by:

- Keeping `USDCSpent` (already correct)
- Adding `layOffset` to separate Lay token flow
- Deriving `virtualOffset = USDCSpent + layOffset`

---

## Current State (Works, But Confusing)

```solidity
availableShares[k] = freeCollateral + AllocatedCapital + tilt[k];
```

| Variable | Meaning |
|-----------|----------|
| `AllocatedCapital` | Hybrid — `USDCSpent + net Lay flow` |
| `USDCSpent` | Real USDC spent into market (correct, but not used in solvency) |

---

## New Model (Clear & Safe)

```text
availableShares[k] 
    = freeCollateral 
    + virtualOffset 
    + tilt[k]
```

```solidity
virtualOffset = USDCSpent + layOffset;
```

| Variable | Type | Meaning |
|-----------|------|----------|
| `USDCSpent[mmId][marketId]` | `int256` | Real USDC spent into market — can be negative (profit) |
| `layOffset[mmId][marketId]` | `int256` | Net Lay flow — `+` = received Lay, `–` = issued Lay |
| `tilt[mmId][marketId][k]` | `int128` | Net Back flow on position *k* |

---

## Changes (Minimal)

| File | Change |
|------|---------|
| **StorageLib.sol** | Remove `AllocatedCapital`<br>Keep `USDCSpent` *(int256)*<br>Add `layOffset` *(int256)* |
| **AllocateCapitalLib.sol** | `USDCSpent += amount` / `-= amount` |
| **TradingLib.sol** | `emitLay:` `layOffset -= amount`<br>`receiveLay:` `layOffset += amount` |
| **SolvencyLib.sol** | Replace `AllocatedCapital` with `USDCSpent + layOffset` |
| **deallocateExcess** | Same logic, just use `USDCSpent` |

---

## Profit

- `USDCSpent` goes negative when you profit from Lay  
- `USDCSpent < 0` → profit taken  

---

## Summary

✅ No new names  
✅ No behavior change  
✅ Just clarity  

**Ready for synthetic liquidity.**
