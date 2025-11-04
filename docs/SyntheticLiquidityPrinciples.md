# Synthetic Liquidity Guiding Principles

## Rules

### Principle 1
ISC is used as collateral in the ledger

The synthetic liquidity (ISC) is added to freeCollateral in availableShares and solvency checks — it acts like real USDC for trading.

### Principle 2
The synthetic liquidity can only be used by the designated market maker

### Principle 3
Synthetic liquidty is created once at market creation

### Principle 4
Designated market maker doesnt change

### Principle 5
Profit only when ISC is refilled

You can only withdraw profit (take USDCSpent negative) after the synthetic liquidity has been fully replaced by real user inflows.

### Principle 6
Redeemable sets backed by real USDC

Every complete set of position tokens in circulation must be backed by real USDC, not synthetic liquidity.

### Formula
Redeemable shares is = -layoffset - maxTilt (can be negative)

so USDCSpent >= Redeemable shares

USDCSpent >= -layoffset - maxTilt