# Market Initialisation Sequence


> ⚙️ **Before You Begin**  
> See [ContractDeployment.md](ContractDeployment.md) for initial deployment of contracts.

## 0 · About the market being created

Here we are creating a market of fruit initially with 3 positions Apple Banana and Cucumber. We are using synthetic liquidity of 10000 USDC. The initial prices of our back positions are 0.4, 0.1, 0.3 with the reserve or other position at (0.2).
Thus the lay prices are 0.6, 0.9, 0.7 and (0.8) respectively

We then add another position Dragon Fruit splitting its price as 50%(0.5e18) of the reserve (other) which sets the price of back Dragon Fruit as 0.1 and also reduces the price of back other to (0.1).


## 1 · Create Market on Ledger

The owner creates a new market entry:

```solidity
MarketMakerLedger.createMarket(name, ticker, dmmId, iscAmount);
```

### Example
```solidity
createMarket ("Fruit", FRT, 0, 10000000000)
```

---

## 2 · Create Initial Positions


```solidity
MarketMakerLedger.createPositions(marketId, PositionMeta[]);
```

### Example

```solidity
createPositions(marketId, [
    { name: "Apple",    ticker: "APL" },
    { name: "Banana",   ticker: "BAN" },
    { name: "Cucumber", ticker: "CUC" }
]);
```


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

### Example

```solidity
initMarket(
    0,
    { positionId: "0",    weight: "4" },
    { positionId: "1",   weight: "1" },
    { positionId: "2", weight: "3" },
    10000000000,
    2,
    true
);
```

---

## 4 · Adding Additional Position


### 1 ·Add Position to Ledger

```solidity
MarketMakerLedger.addPositionToExpandingMarket(
    marketId,
    name,
    ticker
);
```

#### Example
```solidity
addPositionToExpandingMarket(
  0,
  "Dragon Fruit"
  "DRF"
)
```

### 2 ·Add Position to AMM


Using `splitFromReserve` 

```solidity
LMSRMarketMaker.splitFromReserve(
    marketId,
    ledgerPositionId,
    alphaWad
);
```

##### Example
```solidity
listPosition(
  0,
  3,
  500000000000000000
)
```
## Token Names

See [**Token Names**](TokenNames.md)
