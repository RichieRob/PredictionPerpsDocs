---
title: Synthetic Liquidity — Implementation Changes (Updated)
---

# Synthetic Liquidity — Implementation Changes

## 1. Storage Structure

Synthetic Liquidity (ISC) is now **isolated per market** and controlled only by the **designated market maker** (DMM) for that market.

```solidity
// --- Real collateral (per mmId) ---
mapping(uint256 => uint256) freeReal;                               // mmId => free real USDC
mapping(uint256 => mapping(uint256 => uint256)) allocatedReal;      // mmId => marketId => allocated real

// --- Synthetic ISC (per market) ---
mapping(uint256 => bool) iscEnabled;           // marketId => enabled
mapping(uint256 => uint256) ISC_seed;          // marketId => initial seeded depth
mapping(uint256 => uint256) freeISC;           // marketId => unallocated ISC
mapping(uint256 => uint256) allocatedISC;      // marketId => allocated ISC (total)
mapping(uint256 => uint256) designatedMM;      // marketId => mmId authorized to use ISC

// --- Split counters (Real vs ISC) ---

// Real side — tracked per (mmId, marketId)
mapping(uint256 => mapping(uint256 => int256)) USDCSpentReal; // mmId => marketId => int
mapping(uint256 => uint256) MarketUSDCSpentReal;              // marketId => uint
mapping(uint256 => uint256) marketValueReal;                  // marketId => uint
uint256 TotalMarketsValueReal;

// ISC side — tracked per market (single designated MM only)
mapping(uint256 => int256) USDCSpentISC;                      // marketId => int
mapping(uint256 => uint256) MarketUSDCSpentISC;               // marketId => uint
mapping(uint256 => uint256) marketValueISC;                   // marketId => uint
uint256 TotalMarketsValueISC;

// --- Split TVL tracking ---
uint256 totalValueLockedReal;   // deposits of Real only
uint256 totalValueLockedISC;    // seeded synthetic capacity (optional analytics)
```

**Key points**
- ISC state exists **once per market**, not globally.
- Each market can have **only one designated MM**.
- No global `totalValueLockedISC` invariant — each market’s ISC is isolated.

---

## 2. Library Overview

### A. `AllocateISCCapitalLib.sol`
Handles **synthetic liquidity** for a market’s designated MM.

- `seedISC(marketId, mmId, seed)` → initializes ISC for that market and assigns the designated MM.
- `allocate(mmId, marketId, amount)`  
  → only callable by the **designated MM**.  
  Moves `freeISC → allocatedISC`.  
  Updates ISC-side counters:
  ```solidity
  USDCSpentISC[marketId]         += int256(amount);
  MarketUSDCSpentISC[marketId]   += amount;
  marketValueISC[marketId]       += amount;
  TotalMarketsValueISC           += amount;
  ```
- `deallocate(mmId, marketId, amount)`  
  → only callable by the **designated MM**.  
  Refills `freeISC` up to `ISC_seed`, reverses the counters above.
- `isFull(marketId)` → checks if ISC is fully refilled.

---

### B. `AllocateRealCapitalLib.sol`
Handles **real capital** for all MMs.

- `allocate(mmId, marketId, amount)` → move `freeReal → allocatedReal`.  
  Updates Real-side counters:
  ```solidity
  USDCSpentReal[mmId][marketId]  += int256(amount);
  MarketUSDCSpentReal[marketId]  += amount;
  marketValueReal[marketId]      += amount;
  TotalMarketsValueReal          += amount;
  ```
- `deallocate(mmId, marketId, amount)` → move `allocatedReal → freeReal`.  
  Reverses the Real-side counters.

---

### C. `AllocateCapitalLib.sol`
Acts as the **coordinator** between Real and ISC layers.  
Now includes a **designated MM restriction** on ISC operations.

#### `allocate(mmId, marketId, amount)`
1. If `mmId == designatedMM[marketId]`, call `AllocateISCCapitalLib.allocate(...)`.
2. Allocate any remaining `amount` from Real via `AllocateRealCapitalLib.allocate(...)`.
3. Revert if still short.
4. Update `AllocatedCapital += amount`.

#### `deallocate(mmId, marketId, amount)`
1. If `mmId == designatedMM[marketId]`, call `AllocateISCCapitalLib.deallocate(...)` first to refill ISC.
2. Deallocate any remaining from Real.
3. Update `AllocatedCapital -= totalReleased`.

This conditional logic ensures:
- Only the designated MM ever touches ISC.
- All other MMs behave as pure Real-capital participants.

---

## 3. Counters & Combined Views

All previous exposure counters are now **split into Real and ISC** variants.  
To preserve compatibility, new “combined” view getters expose unified totals:

```solidity
function USDCSpentComb(uint256 mmId, uint256 marketId)
    internal view returns (int256)
{ return s.USDCSpentReal[mmId][marketId] + s.USDCSpentISC[marketId]; }

function MarketUSDCSpentComb(uint256 marketId)
    internal view returns (uint256)
{ return s.MarketUSDCSpentReal[marketId] + s.MarketUSDCSpentISC[marketId]; }

function marketValueComb(uint256 marketId)
    internal view returns (uint256)
{ return s.marketValueReal[marketId] + s.marketValueISC[marketId]; }

function TotalMarketsValueComb()
    internal view returns (uint256)
{ return s.TotalMarketsValueReal + s.TotalMarketsValueISC; }

function totalValueLockedComb()
    internal view returns (uint256)
{ return s.totalValueLockedReal + s.totalValueLockedISC; }
```

---

## 4. Cash-Out / Skim Guards

### A. `withdrawInterest()`
```solidity
require(ISCLib.isFull(marketId), "ISC_NOT_FULL");
```
— ensures the synthetic buffer is fully restored before Real yield is withdrawn.

### B. Payout / Redemption
```solidity
require(s.freeReal[mmId] >= amount, "INSUFFICIENT_REAL");
```
— all user-facing payouts are **Real-only**.

---

## 5. Events

```solidity
event ISCSeeded(uint256 marketId, uint256 mmId, uint256 amount);
event ISCAllocated(uint256 marketId, uint256 mmId, uint256 amount);
event ISCDeallocated(uint256 marketId, uint256 mmId, uint256 amount);
event ISCFilled(uint256 marketId);
```

---

### Summary

| Concept | Scope | Controlled By | Notes |
|----------|--------|---------------|-------|
| **ISC pool** | per-market | designated MM only | Synthetic liquidity buffer |
| **Real capital** | per-MM | any MM | Real USDC backing |
| **Counters** | split Real/ISC | updated on allocate/deallocate | Same timing as before |
| **Coordinator** | both layers | conditional ISC usage | Reverts if insufficient backing |
| **Cash-out** | Real-only | all MMs | No synthetic exposure to payouts |
| **Interest skim** | Real-only | owner | Requires ISC full first |