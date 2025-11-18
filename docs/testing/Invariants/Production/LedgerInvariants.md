---
title: Ledger Invariants
description: Accounting, solvency, and synthetic-liquidity invariants enforced by MarketMakerLedger and its libraries.
---

# Ledger Invariants

This page describes the **intended invariants** of the `MarketMakerLedger` and its libraries:

- purely at the **ledger layer** (USDC/aUSDC, collateral, synthetic credit, ERC-1155 mint/burn),
- independent of any particular AMM or pricing model.

It’s written to drive both **reasoning** and **tests**.

---

## 0 · Notation & Scope

We use:

- `mmId` — market maker ID (`mmIdToAddress[mmId]`).
- `marketId` — market ID.
- `positionId` — position index in that market.
- `s` — shorthand for `StorageLib.getStorage()`.

Core fields:

- `s.freeCollateral[mmId]` — free (unallocated) USDC-equivalent collateral for an MM.
- `s.totalFreeCollateral` — sum of free collateral across all MMs.
- `s.MarketUSDCSpent[marketId]` — total real USDC put into a market (all MMs).
- `s.Redemptions[marketId]` — total full sets redeemed from a market.
- `s.marketValue[marketId]` — real USDC value still allocated to the market.
- `s.TotalMarketsValue` — sum of all `marketValue[marketId]`.
- `s.totalValueLocked` — principal actually held in Aave on behalf of ledger users.
- `s.syntheticCollateral[marketId]` — ISC credit line for that market.
- `s.marketToDMM[marketId]` — designated DMM for that market.
- `s.USDCSpent[mmId][marketId]` — real capital spent by an MM on a market (signed).
- `s.layOffset[mmId][marketId]` — net Lay flow (signed).
- `s.tilt[mmId][marketId][positionId]` — per-position tilt.
- heap structures tracking min/max tilt.

Solvency helpers:

- `realMin = USDCSpent + layOffset + minTilt`
- `effMin = realMin + syntheticCollateral` for the DMM, else `realMin`
- `redeemable = -layOffset - maxTilt`

---

## 1 · Core Accounting Invariants

### 1.1 Non-negativity

All core ledger quantities must remain ≥ 0:
- freeCollateral, totalFreeCollateral
- MarketUSDCSpent
- Redemptions
- marketValue
- TotalMarketsValue
- totalValueLocked

### 1.2 Market value identity

marketValue = MarketUSDCSpent - Redemptions

### 1.3 Global markets value

TotalMarketsValue = Σ marketValue

### 1.4 Global free collateral

totalFreeCollateral = Σ freeCollateral

### 1.5 Principal conservation

totalValueLocked = TotalMarketsValue + totalFreeCollateral

### 1.6 Aave safety

aUSDC.balanceOf(ledger) ≥ totalValueLocked

---

## 2 · Synthetic Liquidity Invariants

We define a derived (view-only) quantity:

iscSpent(marketId) = max(0, -realMin(DMM, marketId))

### 2.1 credit line static

syntheticCollateral is immutable per market.

### 2.2 usage ≤ credit line

iscSpent(marketId) ≤ syntheticCollateral[marketId]

---

## 3 · MM Solvency Invariants (per mm, per market)

### 3.1 effMin ≥ 0

For DMM: effMin = realMin + syntheticCollateral ≥ 0  
For non‑DMM: effMin = realMin ≥ 0

### 3.2 redeemable bounded

USDCSpent ≥ redeemable

### 3.3 deallocateExcess correctness

After deallocateExcess, any further deallocation would violate either:
- effMin ≥ 0, or
- USDCSpent ≥ redeemable, or
- (for DMMs) realMin ≥ -syntheticCollateral

---

## 4 · Token & Exposure Invariants

Let:
- Bᵢ = total Back token supply for outcome i
- mmExposureᵢ = exposure of the MM implied by ledger accounting
- Eᵢ = Bᵢ + mmExposureᵢ

### 4.1 Balanced system exposure

For all outcomes i,j:

Eᵢ = Eⱼ

→ system holds exactly E full sets.

### 4.2 Full sets = principal + synthetic

For each market:

E = marketValue + iscSpent

### 4.3 user-side full sets

fullSetsUser = min_i Bᵢ

Invariant:

fullSetsUser ≤ E

---

## 5 · Summary for Testing

Test:

1. marketValue, TotalMarketsValue, totalFreeCollateral, totalValueLocked identities  
2. effMin ≥ 0 for all MMs/markets  
3. redeemable bounded  
4. iscSpent ≤ syntheticCollateral  
5. Token ↔ ledger consistency:  
   - all Eᵢ equal  
   - E = marketValue + iscSpent  
   - fullSetsUser ≤ E
