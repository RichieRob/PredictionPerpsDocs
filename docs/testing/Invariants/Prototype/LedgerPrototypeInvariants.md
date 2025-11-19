---
comment: true
title: Ledger Prototype — Invariants (1 MM, 1 Market)
slug: ledger-prototype-invariants
description: Invariants and sanity checks for the minimal ledger prototype with one market maker and one market, with dummy Aave and synthetic liquidity enabled.
---

# Ledger Prototype — Invariants  
### *(Single MM · Single Market · Dummy Aave · Synthetic Liquidity)*

This document specifies the **exact invariants** to test in the prototype ledger.

## 0 · Prototype Context

- Only one market maker (mmId = 0)
- Only one market (marketId = 0)
- MM is also the DMM for this market
- Aave replaced by dummy 1:1 vault
- Ledger must enforce balanced exposure across outcomes

## 1 · Core Accounting Invariants

- All non-negativity constraints
- marketValue = MarketUSDCSpent - Redemptions
- totalFreeCollateral == freeCollateral
- TotalMarketsValue == marketValue
- totalValueLocked == marketValue + freeCollateral
- aUSDC.balanceOf(this) == totalValueLocked

## 2 · Synthetic Liquidity Invariants

iscSpent = max(0, -realMin)

- syntheticCollateral immutable
- iscSpent <= syntheticCollateral

## 3 · Solvency Invariants

effMin = realMin + syntheticCollateral >= 0  
redeemable <= USDCSpent  
deallocateExcess correctness

## 4 · Exposure Invariants

User

UserExposure_i = B_i + sum(L_j for j != i)  

MarketMaker
netUSDCAllocation = USDCSpent - redeemedUSDC
mmExposure_i = netUSDCAllocation + iscSpent + layOffset + tilt[i] 
E_i = UserExposure_i + mmExposure_i  

### Must always satisfy:

E_i == E_j for all outcomes  
E = marketValue + iscSpent  
fullSetsUser <= E

--8<-- "link-refs.md"
