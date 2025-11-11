# LMSR Purchase Flow

This document outlines the full execution flow for a **buyForUSDC** transaction through our LMSR AMM.

---

## 0 · Entry Point: User Calls `buyForUSDC` (User → LMSR)

User invokes the `buyForUSDC` function on the `LMSRMarketMaker` contract, providing exact USDC input and expecting tokens out (with slippage protection via `minTokensOut`).

```solidity
buyForUSDC(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 usdcIn,
    uint256 tMax,             // unused (ABI compatibility)
    uint256 minTokensOut,
    bool usePermit2,
    bytes calldata permitBlob
)
```

---

## 1 · Initialization and Listing Check (LMSR Internal)

Verify the market is initialized and the position is listed in the LMSR (retrieve LMSR slot).

```solidity
require(self.initialized[marketId], "not initialized");
uint256 slot = LMSRHelpersLib.requireListed(
    self, 
    marketId, 
    ledgerPositionId
    )
```

---

## 2 · Pre-Trade TWAP Update (LMSR Internal)

Accrue time-weighted average price (TWAP) using pre-trade prices for the affected slot.
This is because we use lazy Twapping so we update for each position before and after a trade.

```solidity
LMSRTwapO1Lib.updateBeforePriceChange(
    self, 
    marketId, 
    slot)
```

---

## 3 · Quote Tokens Out (LMSR Internal)

Compute exact tokens out (`tOut`) for the given USDC in using closed-form quote (fee stripped internally).

```solidity
tOut = LMSRQuoteLib.quoteBuyForUSDCInternal(
    self, 
    marketId, 
    ledgerPositionId, 
    isBack, 
    usdcIn);
```

---

## 4 · Slippage Check (LMSR Internal)

Ensure computed tokens out meet the minimum threshold and are positive.

```solidity
require(
    tOut >= minTokensOut && tOut > 0, 
    "slippage"
    )
```

---

## 5 · Execute on Ledger (LMSR → Ledger)

LMSR forwards trade params + `permitBlob` to the Ledger for fund movement, accounting, and minting.

```solidity
self.ledger.processBuy(
    msg.sender, 
    marketId, 
    self.mmId[marketId],
    ledgerPositionId, 
    isBack, 
    usdcIn, 
    tOut, 
    0,
    usePermit2, 
    permitBlob
)
```

### Flow continues in the Ledger
[ **Ledger Purchase Flow**](PurchaseFlowLedger.md)

---

## 6 · Apply State Update (LMSR Internal)

O(1) update to LMSR state (`G`, `R[slot]`, `S_tradables`) based on the trade (BACK/LAY, buy direction).

```solidity
LMSRUpdateLib.applyUpdateInternal(
    self, 
    marketId, 
    slot, 
    isBack, 
    true, 
    tOut)
```

---

## 7 · Post-Trade TWAP Update (LMSR Internal)

Baseline TWAP after the price change for the affected slot.

```solidity
LMSRTwapO1Lib.updateAfterPriceChange(
    self, 
    marketId, 
    slot)
```

---

## 8 · Emit Events (LMSR Internal)

Emit trade and price update events.

```solidity
emit LMSRMarketMaker.Trade(msg.sender, ledgerPositionId, isBack, tOut, usdcIn, true);
emit LMSRMarketMaker.PriceUpdated(
    ledgerPositionId,
    LMSRViewLib.getBackPriceWadInternal(self, marketId, ledgerPositionId)
);
```
## Further Reading
See the Ledger Purchase Flow called in 5

[ **Ledger Purchase Flow**](PurchaseFlowLedger.md)
