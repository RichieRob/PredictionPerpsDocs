---
title: Synthetic Liquidity — Implementation Changes
---

# Synthetic Liquidity — Implementation Changes

## 1. Storage
```solidity
uint256 freeReal;        // rename from freeCollateral
uint256 allocatedReal;
uint256 freeISC;
uint256 allocatedISC;
uint256 ISC_seed;
bool iscEnabled;
```

Ensure `totalValueLocked` tracks **Real only**.

---

## 2. New Libraries

### A. `AllocateISCCapitalLib.sol`
Handles **synthetic liquidity**.
- `allocate(mmId, marketId, amount)` → move `freeISC → allocatedISC`
- `deallocate(mmId, marketId, amount)` → refill ISC to `ISC_seed`, return any remaining amount
- `isFull(mmId, marketId)` / `seed(mmId, marketId)` helpers

### B. `AllocateRealCapitalLib.sol`
Handles **real capital**.
- `allocate(mmId, marketId, amount)` → move `freeReal → allocatedReal`
- `deallocate(mmId, marketId, amount)` → move `allocatedReal → freeReal`

### C. `AllocateCapitalLib.sol`
Modified coordinator.
- `allocate(mmId, marketId, amount)`:
  1. `AllocateISCCapitalLib.allocate(...)`
  2. if short → `AllocateRealCapitalLib.allocate(...)`
  3. revert if still short
- `deallocate(mmId, marketId, amount)`:
  1. `AllocateISCCapitalLib.deallocate(...)`
  2. if excess remains → `AllocateRealCapitalLib.deallocate(...)`

---

## 3. Cash-Out / Skim Guards

### A. `withdrawInterest()`
```solidity
require(s.freeISC == s.ISC_seed, "ISC_NOT_FULL");
```
before Aave withdraw.

### B. Payout / Redemption Paths
```solidity
require(s.freeReal >= amount, "INSUFFICIENT_REAL");
```
Use **Real only** for payouts.

---

## 4. Events
```solidity
event ISCSeeded(uint256 mmId, uint256 marketId, uint256 amount);
event ISCAllocated(uint256 mmId, uint256 marketId, uint256 amount);
event ISCDeallocated(uint256 mmId, uint256 marketId, uint256 amount);
event ISCFilled(uint256 mmId, uint256 marketId);
```
