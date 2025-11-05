# Top Level Changes for Synthetic Liquidity (ISC)

## What ISC Is
ISC is a fixed virtual budget (e.g., 10,000 synthetic USDC) for new markets. It lets trading start immediately without real money. Assigned to one DMM per market. Real user buys replace it over time. Profits unlock when real_minShares >= 0 (no ISC drawn). Real payouts use real money only.

## Changes Listed

### Market Creation
- Add parameter for DMM ID.
- Add parameter for ISC amount.
- Store DMM ID (immutable).
- Store ISC amount (fixed, immutable).

### Storage
- New mappings:
  - Market to DMM.
  - Market to ISC amount.
- Add max-heap structures (copy of min-heap but for highs).

### Pricing and Liquidity Views
- If caller is DMM, add ISC to freeCollateral in calculations.
- Update available shares to include ISC if caller is DMM.

### Heaps
- Update tilt calls both min and max heaps.
- Add max rescan, update, bubble functions (flipped comparisons).
- Add getMaxTilt view (like getMinTilt).

### Solvency Checks
- Compute real_minShares = USDCSpent + layOffset + minTilt.
- Compute effective_minShares = real_minShares + (if caller is DMM then ISC else 0).
- In ensureSolvency:
  - If effective_minShares < 0, allocate uint(-effective_minShares) real to USDCSpent (revert if insufficient freeCollateral).
  - Compute redeemable = -layOffset - maxTilt.
  - If redeemable > 0 and USDCSpent < redeemable, allocate uint(redeemable - USDCSpent) real (revert if insufficient freeCollateral).
- In deallocateExcess:
  - If effective_minShares > 0:
    - Compute amount = uint(effective_minShares).
    - Compute redeemable = -layOffset - maxTilt.
    - If redeemable > 0, cap amount = min(amount, uint(USDCSpent - redeemable)).
    - If caller is DMM and real_minShares < 0, further cap amount = min(amount, uint(USDCSpent)).
    - Deallocate the capped amount.

### Other
- Trading, deposits, withdrawals, redemptions: No direct changes (use updated solvency).
- Tests: Early trades with 0 real; profits when real_minShares >=0; redemptions need real; non-DMM unchanged.