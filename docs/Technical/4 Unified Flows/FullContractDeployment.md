---
comments: true
slug: full-contract-deployment
title: Full Contract Deployment
---

## 1 · Deploy Core Contracts

 - Deploy `PositionToken1155`

 - Deploy `MarketMakerLedger`

 - Deploy `LMSRMarketMaker`

---

## 2 · Link Contracts

```solidity
PositionToken1155.setLedger(MarketMakerLedger_address);
```


---

## 3 · Whitelist AMM 

### 1 Get the appropriate mmId from the deployment 

from

```solidity
event MarketMakerRegistered(
    address indexed mmAddress,
    uint256 mmId)
```
or 

```solidity
LMSRMarketMaker.mmId() 
```

### 2 call the allowDMM function passing mmId


```solidity
ledger.allowDMM(mmId, true);
```

