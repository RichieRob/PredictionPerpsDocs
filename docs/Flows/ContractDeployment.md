## 1 · Deploy Core Contracts

### Step 1 — Deploy `PositionToken1155`

Deploy the ERC-1155 contract responsible for minting BACK and LAY tokens.

### Step 2 — Deploy `MarketMakerLedger`

Deploy the main ledger contract to manage markets, collateral, and accounting.

### Step 3 — Deploy `LMSRMarketMaker`

Deploy the AMM contract for managing pricing and market operations.

- Upon deployment, it automatically registers an `mmId` via:
  ```solidity
  ledger.registerMarketMaker()
  ```

---

## 2 · Link Contracts

From the deployer address, permanently link the two core contracts:

```solidity
PositionToken1155.setLedger(MarketMakerLedger_address);
```

> ⚠️ This can only be called once — it permanently binds the ledger to the token contract.

---

## 3 · Whitelist AMM 



Allow the AMM to interact with the ledger:

```solidity
ledger.allowDMM(mmId, true);
```


## Summary

| Step | Description |
|------|--------------|
| 1 | Deploy contracts |
| 2 | Link contracts |
| 3 | Whitelist AMM  |