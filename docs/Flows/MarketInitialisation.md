# Succinct Flow for Creating a Market with synethetic Liquidity from Scratch

This guide outlines the full sequence of steps required to create a market with synthetic liquidity on the PredictionPerps protocol.

---


> ⚙️ **Before You Begin**  
> See [ContractDeployment.md](ContractDeployment.md) for detailed instructions on how to deploy and set up the required contracts.

## 1· Create Market on Ledger

The owner creates a new market entry:

```solidity
MarketMakerLedger.createMarket(name, ticker, dmmId, iscAmount);
```

**Returns:** `marketId`

**Stores:**
- Market metadata in `PositionToken1155`
- Core details (`DMM`, `ISC` seed, etc.) in Ledger storage

---

## 2 · Create Initial Positions

Define all positions within the market.

```solidity
MarketMakerLedger.createPositions(marketId, PositionMeta[]);
```

### Example

```solidity
createPositions(marketId, [
    { name: "Apple",    ticker: "A" },
    { name: "Banana",   ticker: "B" },
    { name: "Cucumber", ticker: "C" }
]);
```

**Returns:** array of `positionIds`, e.g. `[1, 2, 3]`  
**Effect:** generates BACK and LAY ERC-1155 token IDs and updates storage.

---

## 3 · Initialize Market on AMM

Once positions are created, initialize the market in the AMM:

```solidity
LMSRMarketMaker.initMarket(
    marketId,
    initialPositions[],
    liabilityUSDC,
    reserve0,
    isExpanding
);
```

### Parameters

| Parameter | Description |
|------------|--------------|
| `initialPositions[]` | Array of `{ positionId, r }` values |
| `liabilityUSDC` | Example: `1e6` (1 USDC = 1e6 wei) |
| `reserve0` | Reserve bucket (used if expanding) |
| `isExpanding` | `true` if new positions can be added later |

### Notes
- The AMM can read the ISC amount from the ledger to set its liability.  
- The relationship between parameters follows:

\[
s = \sum r + \text{reserve}_0
\]
\[
\text{price}(i) = \frac{r_i}{s}
\]

**Effect:** sets AMM state (`b`, `G`, `R`, `S`, and mappings) and marks the market as tradable.

---

## 4 · Adding Additional Positions

*(Only applicable if `isExpanding = true`)*

### Add Position to Ledger

```solidity
MarketMakerLedger.addPositionToExpandingMarket(
    marketId,
    name,
    ticker
);
```

### Add Position to AMM

The governor can register the new position using one of two methods:

#### a) `listPosition` 

```solidity
LMSRMarketMaker.listPosition(
    marketId,
    ledgerPositionId,
    priorR
);
```

#### b) `splitFromReserve` 

```solidity
LMSRMarketMaker.splitFromReserve(
    marketId,
    ledgerPositionId,
    alphaWad
);
```

**Effect:** extends the AMM to include the new position and rebalances full market or splits price from the reserve as needed.

---

## Summary

| Step | Description |
|------|--------------|
| 1 | Create the market on the ledger |
| 2 | Create initial positions on the ledger |
| 3 | Initialize the market on the AMM |
| 4 | Adding additional positions |

---

