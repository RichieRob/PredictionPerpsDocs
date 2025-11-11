# Purchase Flow (AMM‑Agnostic)

This page defines the **core sequence** for purchasing a position using **Permit2**, independent of any specific AMM design.  

---

## Core Purchase Sequence (AMM‑Agnostic)

### 1 · Quote (Trader → AMM)
Trader requests a quote to estimate tokens_out for a given USDC_in.
```solidity
amm.quoteBuyForUSDC(marketId, positionId, isBack, usdcIn, 0) → tOut
```

### 2 · Sign Permit (Trader → Ledger)
Trader signs an EIP‑712 **Permit2** `PermitSingle` with:
```
token = USDC
amount = usdcIn
spender = Ledger
sigDeadline / nonce = tightly scoped
```

### 3 · Execute on AMM (Trader → AMM)
Trader submits the trade with the Permit2 payload.
```solidity
amm.buyForUSDC(
  marketId, positionId, isBack,
  usdcIn, 0,                // tMax (unused)
  minTokensOut,             // slippage guard
  true,                     // usePermit2
  permitBlob                // abi.encode(PermitSingle, signature)
);
```

### 4 · Exectute on Ledger (AMM → Ledger)
AMM forwards trade params + `permitBlob` to the Ledger for fund movement and accounting.
```solidity
ledger.executeBuyForUSDCWithPermit2(
  trader, marketId, positionId, isBack, usdcIn, minTokensOut, permitBlob
) returns (uint256 tOut);
```

### 5 · Pull Funds (Ledger → USDC)
Ledger validates the permit and **pulls USDC**.
```solidity
IPermit2(s.permit2).permitTransferFrom(permit2Calldata, trader, address(this), amount);
```

### 6 · Deposit to Aave  (Ledger → Aave)
Ledger supplies USDC to Aave, receiving interest‑bearing tokens.
```solidity
aavePool.supply(address(s.usdc), amount, address(this), 0);
```

### 7 · Apply Protocol Fee (if enabled)
Skim fee from the received aTokens **before** crediting collateral.
```solidity
uint256 recordedAmount = ProtocolFeeLib.skimOnAaveSupply(aReceived);
```

### 8 · Credit collateral (Ledger Internal)
Credit collateral and enforce solvency/constraints (incl. synthetic credit rules).
```solidity
// Credit real collateral
s.freeCollateral[mmId] += recordedAmount;
s.totalFreeCollateral  += recordedAmount;
s.totalValueLocked     += recordedAmount;

// Token-flow solvency
updateTilt(marketId, positionId, isBack, tOut);
checkMinSharesNonNegative(mmId, marketId);
```

### 8b · Enforce Redeemability (Synthetic Credit)
When synthetic credit (ISC) is in use, ensure **real** capital is sufficient against redeemable exposure, and refill ISC first.

```solidity
require(spentReal >= int256(maxTilt), "Redeemability: insufficient real backing");
```


### 9 · Mint Instruction (Ledger → ERC‑1155)
Ledger authorizes mint of Back/Lay tokens to the trader.
```solidity
PositionToken1155.mintBackOrLay(trader, marketId, positionId, isBack, tOut);
```

### 10 · ERC‑1155 Minting (Token Contract)
ERC‑1155 contract mints to the trader.
```solidity
_mint(trader, tokenId /* Back/Lay */, tOut, "");
```

---
