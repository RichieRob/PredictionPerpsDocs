
# LMSRMarketMaker Refactor — Quoted Subset & Immutable Pricing

## Overview

This update introduces **partial quoting** for AMMs: each AMM can quote prices for a subset of Ledger positions, while the Ledger remains the full canonical record.  
Positions can be created freely in the Ledger, but only those explicitly *enabled* on the AMM will have live prices.

Additionally, once a position is enabled for trading, **it cannot be disabled**, ensuring fairness for traders who already hold tokens.

---

## 1. Goals

- **Decouple position creation from quoting**: Ledger can create new positions at any time; AMM selectively lists them.
- **Preserve fairness**: once a position is listed (quoted), it cannot later be unlisted.
- **Keep denominators consistent** with a non-tradable reserve mass.
- **Ensure price continuity**: adding new quoted positions adjusts the reserve, keeping total mass constant.
- **Align indexing**: Ledger `positionId` remains the canonical identifier, while AMM maintains local slot indices.

---

## 2. Core Data Structures

### New

```solidity
struct Slot {
    uint256 ledgerId;  // Ledger position ID
    int256  R;         // Base mass (1e18)
}
```

### Storage

```solidity
Slot[] public slots;                        // quoted tradable subset
mapping(uint256 => uint256) public slotOf;  // ledgerId -> slotIndex+1 (0 = not quoted)

int256 public S_tradables;                  // sum of R over quoted slots
int256 public R_reserve;                    // non-tradable base mass
bool public isExpanding;                    // allows new positions
```

---

## 3. Initialization

Constructor changes:

```solidity
constructor(
    address _ledger,
    address _usdc,
    uint256 _marketId,
    uint256 _mmId,
    uint256 _numTradables,
    int256  _b,
    int256[] memory initialR,
    int256  reserve0,
    bool    _isExpanding
)
```

- Initializes `slots[]` and `slotOf`.
- If `_isExpanding` is `false`, `reserve0` must be 0.
- If `_isExpanding` is `true`, `reserve0 > 0` required.

---

## 4. Quoting Control

### Enable Quote (irreversible)

```solidity
function enableQuote(uint256 ledgerId, int256 alphaWad) external onlyOwner {
    require(isExpanding, "not expanding");
    require(slotOf[ledgerId] == 0, "already quoted");
    require(alphaWad > 0 && alphaWad <= 1e18, "bad α");

    int256 before = R_reserve;
    int256 Rnew = (before * alphaWad) / 1e18;
    R_reserve = before - Rnew;

    Slot memory s = Slot({ ledgerId: ledgerId, R: Rnew });
    slotOf[ledgerId] = slots.length + 1;
    slots.push(s);
    S_tradables += Rnew;

    emit PositionEnabled(ledgerId, alphaWad, before, R_reserve, Rnew);
}
```

**No disable path** — once enabled, a position remains quoted permanently.

---

## 5. Denominator and Pricing

```solidity
function _denom() internal view returns (int256) {
    return S_tradables + R_reserve;
}
```

### Back price

```solidity
function getBackPriceWad(uint256 ledgerId) public view returns (uint256) {
    uint256 idx1 = slotOf[ledgerId];
    require(idx1 != 0, "not quoted");
    Slot storage s = slots[idx1 - 1];
    int256 d = _denom();
    return uint256((s.R * 1e18) / d);
}
```

### Reserve (UI)

```solidity
function getReservePriceWad() public view returns (uint256) {
    int256 d = _denom();
    return uint256((R_reserve * 1e18) / d);
}
```

---

## 6. State Update (ΔU_rest / ΔU_k)

```solidity
function _applyUpdate(uint256 ledgerId, bool isBack, bool isBuy, uint256 t) internal {
    uint256 idx1 = slotOf[ledgerId];
    require(idx1 != 0, "not quoted");
    Slot storage s = slots[idx1 - 1];

    int256 Ri_old = s.R;
    int256 dU_rest = 0;
    int256 dU_k = 0;
    int256 dt = isBuy ? int256(uint256(t)) : -int256(uint256(t));

    if (isBack) dU_k = dt;
    else dU_rest = dt;

    int256 e_rest = _exp_ratio_over_b(dU_rest);
    int256 e_local = _exp_ratio_over_b(dU_k - dU_rest);

    G = _wmul(G, e_rest);
    s.R = _wmul(Ri_old, e_local);

    S_tradables = S_tradables - Ri_old + s.R;
    require(S_tradables > 0, "S underflow");
}
```

`R_reserve` remains unchanged except when explicitly split by `enableQuote`.

---

## 7. Invariants

| Invariant | Description |
|------------|-------------|
| Σ p_i + p_reserve = 1 | Denominator constant |
| Once quoted → always quoted | No unlisting |
| _denom() > 0 | Ensures solvency of price space |
| Ledger/AMM IDs aligned | slotOf mapping preserves canonical position links |

---

## 8. Events

```solidity
event PositionEnabled(
    uint256 indexed ledgerId,
    int256 alphaWad,
    int256 reserveBefore,
    int256 reserveAfter,
    int256 R_new
);
```

---

## 9. Summary

**Ledger**  
- Manages all positions globally.  
- AMM never deletes or disables positions from the Ledger.  

**AMM**  
- Chooses which positions to quote.  
- Once quoted, continues pricing permanently.  
- Keeps denominator (`S_tradables + R_reserve`) constant for continuity.  

This approach allows **market expansion without fragility** while preserving user fairness.
