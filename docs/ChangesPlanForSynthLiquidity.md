# Detailed Implementation Plan for Synthetic Liquidity (ISC)

This document outlines the necessary modifications to the existing codebase to incorporate synthetic liquidity (ISC) based on the provided principles. The goal is to enable markets to start trading immediately upon creation using virtual collateral for the designated market maker (DMM), while ensuring profits can only be withdrawn when ISC is not drawn (real_minShares >= 0), and redeemable sets are always backed by real USDC.

## Key Assumptions
- **Designated Market Maker (DMM)**: Each market has one immutable DMM (identified by `mmId`), set at market creation. Only this DMM can use ISC for that market.
- **ISC Amount**: Configurable per market (passed to `createMarket`), scaled to USDC decimals, created once at market creation.
- **ISC Usage**: ISC is added virtually to calculations in `freeCollateral` for available shares and solvency checks, but it is not real USDC (not deposited to Aave or withdrawable).
- **Refill Check**: No flag; dynamically checked via real_minShares >= 0 (i.e., no ISC drawn). This allows dipping back into ISC if needed.
- **Redeemable Sets**: Enforce `USDCSpent >= max(0, -layOffset - maxTilt)` per MM per market to back complete sets with real USDC. ISC does not apply to this check. Run as additional checks in solvency functions.
- **Max Tilt Tracking**: Add a max-heap symmetric to the existing min-heap to compute `maxTilt`.
- **No Impact on Non-DMMs**: Other MMs operate as before, without ISC.
- **Revert on Insufficient Real**: Allocations for redeemable or solvency revert if freeCollateral is insufficient.

## Modified Files and Changes

### 1. StorageLib.sol
**Add new storage variables:**
- `mapping(uint256 => uint256) public marketToDMM;` // marketId => mmId (immutable)
- `mapping(uint256 => uint256) public syntheticCollateral;` // marketId => ISC amount (immutable)
- For max-heap: Add symmetric structures to the min-heap.
  - `mapping(uint256 => mapping(uint256 => mapping(uint256 => Types.BlockData))) public blockDataMax; // mmId => marketId => blockId => {maxId, maxVal}`
  - `mapping(uint256 => mapping(uint256 => uint256[])) public topHeapMax; // mmId => marketId => heap array`
  - `mapping(uint256 => mapping(uint256 => uint256)) public heapIndexMax; // mmId => marketId => blockId => index+1`

**Updates to existing:**
- No changes to `encodeTokenId` and `decodeTokenId`.

### 2. MarketManagementLib.sol
**Modify `createMarket` function:**
- Add parameters `uint256 dmmId, uint256 iscAmount`.
- Set `s.marketToDMM[marketId] = dmmId;`
- Set `s.syntheticCollateral[marketId] = iscAmount;`
- Emit an event: `event SyntheticLiquidityCreated(uint256 indexed marketId, uint256 amount, uint256 dmmId);`

**New function:**
- `function isDMM(uint256 mmId, uint256 marketId) internal view returns (bool) { return s.marketToDMM[marketId] == mmId; }`

### 3. HeapLib.sol
**Add max-heap logic (symmetric to min-heap):**
- Duplicate functions for max: e.g., `updateTilt` now also calls `_rescanBlockMax` if needed (find maxVal = type(int128).min, update if v > maxVal), and `_updateTopHeapMax`.
- In bubbleUp/Down for max-heap, invert comparisons (use > for max).
- New views: `getMaxTilt(uint256 mmId, uint256 marketId) internal view returns (int128, uint256)` (symmetric to `getMinTilt`, returns maxVal, maxId).

**Modify `updateTilt`:**
- After updating tilt, rescan/update both min and max heaps if the block's min/max changes.

### 4. SolvencyLib.sol
**New helpers (for clarity):**
- `function computeRealMinShares(StorageLib.Storage storage s, uint256 mmId, uint256 marketId) internal view returns (int256) { (int128 minTilt, ) = HeapLib.getMinTilt(mmId, marketId); return s.USDCSpent[mmId][marketId] + s.layOffset[mmId][marketId] + int256(minTilt); }`
- `function computeEffectiveMinShares(StorageLib.Storage storage s, uint256 mmId, uint256 marketId, int256 realMinShares) internal view returns (int256) { uint256 isc = StorageLib.isDMM(mmId, marketId) ? s.syntheticCollateral[marketId] : 0; return realMinShares + int256(isc); }`
- `function computeRedeemable(StorageLib.Storage storage s, uint256 mmId, uint256 marketId) internal view returns (int256) { (int128 maxTilt, ) = HeapLib.getMaxTilt(mmId, marketId); return -s.layOffset[mmId][marketId] - int256(maxTilt); }`

**Modify `ensureSolvency(uint256 mmId, uint256 marketId)`:**
- `StorageLib.Storage storage s = StorageLib.getStorage();`
- `int256 realMin = computeRealMinShares(s, mmId, marketId);`
- `int256 effMin = computeEffectiveMinShares(s, mmId, marketId, realMin);`
- If `effMin < 0`, `uint256 shortfall = uint256(-effMin); AllocateCapitalLib.allocate(mmId, marketId, shortfall);` // Revert if freeCollateral < shortfall
- `int256 redeemable = computeRedeemable(s, mmId, marketId);`
- If `redeemable > 0 && s.USDCSpent[mmId][marketId] < redeemable`, `uint256 diff = uint256(redeemable - s.USDCSpent[mmId][marketId]); AllocateCapitalLib.allocate(mmId, marketId, diff);` // Revert if insufficient

**Modify `deallocateExcess(uint256 mmId, uint256 marketId)`:**
- `StorageLib.Storage storage s = StorageLib.getStorage();`
- `int256 realMin = computeRealMinShares(s, mmId, marketId);`
- `int256 effMin = computeEffectiveMinShares(s, mmId, marketId, realMin);`
- If `effMin > 0`, `uint256 amount = uint256(effMin);`
- `int256 redeemable = computeRedeemable(s, mmId, marketId);`
- If `redeemable > 0`, `amount = min(amount, uint256(s.USDCSpent[mmId][marketId] - redeemable));`
- If `StorageLib.isDMM(mmId, marketId) && realMin < 0`, `amount = min(amount, uint256(s.USDCSpent[mmId][marketId]));` // Cap to prevent negative USDCSpent
- If `amount > 0`, `AllocateCapitalLib.deallocate(mmId, marketId, amount);`

### 5. LedgerLib.sol
**Modify `getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)`:**
- `StorageLib.Storage storage s = StorageLib.getStorage();`
- `uint256 isc = StorageLib.isDMM(mmId, marketId) ? s.syntheticCollateral[marketId] : 0;`
- `freeCollateral = s.freeCollateral[mmId] + isc;`
- Rest unchanged (virtualOffset, tilt).

**Modify `getMinTilt`:**
- Unchanged; add `getMaxTilt` symmetric.

**Modify `getAvailableShares(uint256 mmId, uint256 marketId, uint256 positionId)`:**
- Add ISC to `int256(freeCollateral)` if DMM.

### 6. AllocateCapitalLib.sol
**Unchanged**: The `allocate` require on freeCollateral handles reverts for insufficient real.

### 7. TradingLib.sol
**No direct changes**: `processBuy` and `processSell` call solvency functions, which now include ISC and redeemable logic.

### 8. RedemptionLib.sol
**Unchanged**: Requires `marketValue >= amount` (real USDC).

### 9. DepositWithdrawLib.sol
**Unchanged**: Withdrawals use real freeCollateral only.

### 10. MarketMakerLedger.sol
**Update `createMarket`**: Pass dmmId and iscAmount.
**Update views**: Use libs (automatically include ISC if DMM).

## Testing Considerations
- **Bootstrap**: Create market, trade with 0 real USDC; allow up to ISC draw (realMin <0, effMin >=0).
- **Refill/Profits**: Buy inflows allocate real, push realMin >=0; then allow dealloc to negative USDCSpent.
- **Dip Back**: If outflows drop realMin <0, restrict profits again until refilled.
- **Redeemable**: Issue Lays/positive tilts; ensure allocation if USDCSpent < redeemable; revert if no freeCollateral.
- **Redemptions**: Always real-backed; test with partial ISC draw.
- **Non-DMM**: No ISC; strict realMin >=0.
- **Edges**: Large markets (heaps efficient); insufficient free for alloc (revert); maxTilt changes.

## Potential Open Questions
- Heap gas for large n: BLOCK_SIZE=16 helps.
- Post-tx redeemable: Already covered in solvency (called post-trade).

These changes align with all principles while minimizing disruption.