

# Purchase Flow Front End


---



## 1 · Quote (Trader → AMM)
Trader requests a quote from AMM for tokens_out for a given USDC_in.
```solidity
amm.quoteBuyForUSDC(
    marketId, 
    positionId, 
    isBack, 
    usdcIn, 
    0
    ) returns (uint256 tOut)
```

## 2 · Sign Permit 
Trader signs an EIP‑712 **Permit2** `PermitSingle` with:
```
token = USDC
amount = usdcIn
spender = Ledger
sigDeadline / nonce = tightly scoped
```

## 3 · Execute on AMM (Trader → AMM)
Trader submits the trade with the Permit2 payload.
```solidity
amm.buyForUSDC(
  marketId, 
  positionId, 
  isBack,
  usdcIn, 
  0,            // tMax (unused)
  minTokensOut, // slippage guard
  true,         // usePermit2
  permitBlob    // abi.encode(PermitSingle, signature)
)
```

## Flow continues to the AMM
[ **LMSR Purchase Flow**](PurchaseFlowLMSR.md)