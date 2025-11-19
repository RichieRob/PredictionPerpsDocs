---
comments: true
slug: synthetic-liquidity-principles  # Stable ID, e.g., for linking as /what-is-it/
title: Synthetic Liquidity Principles  # Optional display title
---

# Synthetic Liquidity Guiding Principles

## Rules

DMM is the Designated Market Maker

### Principle 1
ISC is used as collateral in the ledger for the DMM

The synthetic liquidity (ISC) is added to freeCollateral in availableShares and solvency checks — it acts like real USDC for trading.

### Principle 2
The synthetic liquidity can only be used by the designated market maker

### Principle 3
Synthetic liquidty is created once at market creation

### Principle 4
Designated market maker doesnt change

### Principle 5
Profit only when ISC is refilled

DMM can only withdraw profit after the ISC has been fully restored.

### Principle 6
Redeemable sets backed by real USDC

Every complete set of position tokens in circulation must be backed by real USDC, not synthetic liquidity.

#### Formula for Principle 6
Redeemable shares issued by DMM is = -layoffset - maxTilt (can be negative)

so for DMM

 netUSDCAllocation >= Redeemable shares

and thus 

netUSDCAllocation >= -layoffset - maxTilt

## Further Reading
The synthetic principles are founding principles for the development of synthetic liquidity within the prediction perps ledger. For discussion about their implementation start with [**Synthetic Overview**][synthetic-overview]

--8<-- "link-refs.md"
