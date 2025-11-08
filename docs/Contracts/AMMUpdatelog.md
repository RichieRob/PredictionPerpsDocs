// this is a log of the upcoming updates we are making to the AMM.sol
// the changes are to 1) introduce weightings
// and 2) introduce markets with expanding numbers of positions (splitting off a reserve (other) bucket)

# LMSRMarketMaker Refactor — Reserve Outcome & Expanding Markets

This document summarizes the structural and naming changes required to support **weighted priors**, a **non-tradable reserve outcome (“Other”)**, and **market expansion** via `splitFromReserve`.

---

## 1. Goals

- Keep AMM and Ledger indices aligned (no index drift).  
- Add a non-tradable **reserve** mass that contributes to pricing but cannot be traded.  
- Allow **expanding markets** by splitting reserve mass into a new tradable position without changing existing prices.  
- Maintain O(1) updates and backward compatibility for fixed markets.  
- Optionally initialize markets with **weighted priors**.

---

## 2. Terminology (Renames)

| Old Term | New Term | Meaning |
|-----------|-----------|----------|
| ΔU_other | **ΔU_rest** | Global change applied to all non-selected outcomes. |
| q | **R_reserve** | Persistent base mass of the reserve (“Other”). |
| S | **S_tradables** | Sum of R[i] for tradable outcomes only. |
| — | **_denom() = S_tradables + R_reserve** | Denominator used in pricing. |

---

## 3. State Layout (Updated)

**Before**

```solidity
int256 public G;
int256 public S;
int256[] public R;
uint256 public immutable NUM_OUTCOMES;
```

**After**

```solidity
int256 public G;               // exp(U_all / b)
int256[] public R;             // tradables only
int256 public S_tradables;     // sum(R)
int256 public R_reserve;       // non-tradable reserve mass
uint256 public numOutcomes;    // mutable (tradables count)
bool public isExpanding;       // enables splitFromReserve
```

Rationale:  
Reserve is not indexed, so AMM position IDs match Ledger positions permanently.

---

## 4. Constructor

```solidity
constructor(
    address _ledger,
    address _usdc,
    uint256 _marketId,
    uint256 _mmId,
    uint256 _numTradables,
    int256  _b,
    int256[] memory initialR, // base masses
    int256  reserve0,         // 0 for fixed markets
    bool    _isExpanding
)
```

**Logic:**
- Validate inputs.
- Sum `initialR` → `S_tradables`.
- If `_isExpanding == false`, require `reserve0 == 0`.
- If `_isExpanding == true`, require `reserve0 > 0`.
- Initialize:
  - `R_reserve = reserve0`
  - `numOutcomes = _numTradables`
  - `G = 1e18`
  - `isExpanding = _isExpanding`

---

## 5. Pricing & Quotes

**New helper:**

```solidity
function _denom() internal view returns (int256) {
    return S_tradables + R_reserve;
}
```

All existing formulas switch from `S` → `_denom()`.

**Examples:**
```solidity
function getBackPriceWad(uint256 positionId) public view returns (uint256) {
    return uint256((R[positionId] * 1e18) / _denom());
}

function getReservePriceWad() public view returns (uint256) {
    return uint256((R_reserve * 1e18) / _denom());
}
```

`getZ()` → `(G * _denom()) / 1e18`.

---

## 6. Update Rule (No Math Change)

```solidity
// Mapping from action -> (ΔU_rest, ΔU_k)
BACK buy:  (0, +t)
BACK sell: (0, -t)
LAY  buy:  (+t, 0)
LAY  sell: (-t, 0)
```

`_applyUpdate` now updates only `S_tradables` and leaves `R_reserve` untouched.

---

## 7. Expanding Markets — `splitFromReserve`

```solidity
event PositionSplitFromReserve(
    uint256 indexed newPositionId,
    uint256 alphaWad,
    int256 reserveBefore,
    int256 reserveAfter,
    int256 R_new
);
```

```solidity
function splitFromReserve(uint256 alphaWad) external returns (uint256 newPositionId) {
    require(isExpanding, "not expanding");
    require(alphaWad > 0 && alphaWad <= 1e18, "bad α");

    int256 before = R_reserve;
    int256 Rnew = (before * alphaWad) / 1e18;

    R_reserve = before - Rnew;
    R.push(Rnew);
    S_tradables += Rnew;
    numOutcomes++;

    emit PositionSplitFromReserve(newPositionId, alphaWad, before, R_reserve, Rnew);
}
```

**Why prices stay stable:**
\[(S + R_res) = (S + R_new) + (R_res - R_new) = constant\]

Existing prices unchanged;  
new price \(p_{new} = lpha × p_{reserve,prev}\).

---

## 8. Fixed Markets

- `isExpanding = false`, `R_reserve = 0`
- `splitFromReserve()` reverts.

All quote and trade math unchanged.

---

## 9. API Changes

| Change | Old | New |
|--------|-----|-----|
| `NUM_OUTCOMES` | immutable | `numOutcomes` (mutable) |
| `S` | — | replaced with `S_tradables` |
| — | — | `R_reserve`, `isExpanding` |
| — | — | `getReservePriceWad()` |
| — | — | `splitFromReserve(uint256 alphaWad)` |

---

## 10. Ledger / AMM Boundary

- **AMM:** manages `R[]`, `R_reserve`, and `G`.  
  - Appends new tradables via `splitFromReserve`.  
  - Denominator = `S_tradables + R_reserve`.  
- **Ledger:** never mints reserve tokens.  
  - On split, reassigns market maker’s implicit reserve exposure to the new position.

---

## 11. Invariants

| Invariant | Meaning |
|------------|----------|
| Σ p_i + p_reserve = 1 | Prices always sum to 1 |
| _denom() > 0 | No divide-by-zero |
| Prices unchanged after split | Stability |
| Reserve non-tradable | Safety |
| Split only if `isExpanding` | Permissioned growth |

---

## 12. Migration / Backward Compatibility

- Existing fixed markets: deploy with `reserve0 = 0`, `isExpanding = false`.
- Weighted priors supported via non-uniform `initialR`.
- Trade functions (`buy`, `sell`, `quoteBuy`, etc.) unchanged externally.

---

## 13. Tests (Checklist)

1. **Init (fixed)** — prices sum to 1; reserve = 0.  
2. **Init (expanding)** — reserve > 0; prices sum to 1.  
3. **Trade paths** — identical behavior to original when reserve=0.  
4. **Split**  
   - Existing prices unchanged.  
   - New price = α × p_reserve_prev.  
   - `_denom()` constant.  
5. **Edge cases** — α≈1e18 or very small; rounding safe.  

---

## 14. Minimal Diff Summary

- Rename: `S` → `S_tradables`; add `R_reserve`.
- Replace `S` references with `_denom()`.
- Update `_applyUpdate` to only change `S_tradables`.
- Swap immutable `NUM_OUTCOMES` → mutable `numOutcomes`.
- Add `splitFromReserve()` and `getReservePriceWad()`.
- No external interface changes beyond constructor.

---

**Author’s Note:**  
This refactor cleanly introduces an expandable market model while preserving the LMSR’s invariant structure and backward compatibility with all existing logic.
