# Token Purchase Flow Overview

## **1 Front‑End**

- User gets a quote for tokens from the AMM
- User signs a Permit2 approval for USDC
- User calls buy transaction on AMM 

[ **Read More**](PurchaseFlowFrontEnd.md)


## **2 AMM**

- AMM Approves the trade
- AMM updates internal state
- AMM calls processBuy on the Ledger  

[ **Read More about the LMSR AMM Flow**](PurchaseFlowLMSR.md)

## **3 Ledger**

- Ledger pulls USDC from user with Permit2
- Deposits USDC to Aave
- Applies Fees
- Updates Accounting
- Tells ERC1155 Contract to mint to user

[ **Read More:**](PurchaseFlowLedger.md)

## **4 ERC1155**
- Mints tokens to user
