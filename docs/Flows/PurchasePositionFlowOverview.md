# Purchase Position Flow — Key Steps

This page defines the **core sequence** for purchasing a position using **Permit2**,  
where the **Ledger** is the spender that pulls USDC directly from the trader.  

---

## Core Purchase Sequence

### 1 · Quote (Trader → AMM)

The trader requests a quote from an AMM to see how many tokens they will receive for a given USDC input.

```solidity
AMM.quoteBuyForUSDC(
    marketId,
    positionId,
    isBackBool,
    usdcIn,
    0 // tMax (ignored)
) → tOut
```

---

### 2 · Sign Permit (Trader → Ledger)

The trader signs an **EIP-712 Permit2 `PermitSingle`** message authorizing the **Ledger** to pull USDC.

```
token:     USDC
amount:    usdcIn
spender:   Ledger
sigDeadline / nonce: tightly scoped
```

This signature allows the Ledger to transfer the exact `usdcIn` amount once.

---

### 3 · Execute Trade (Trader → AMM)

The trader executes the trade on-chain:

```solidity
AMM.buyForUSDC(
    marketId,
    positionId,
    true,          // isBack
    usdcIn,
    0,             // tMax (unused)
    minTokensOut,  // slippage guard
    true,          // usePermit2
    permitBlob     // abi.encode(PermitSingle, signature)
);
```

This sends all trade parameters and the signed permit data to the AMM.

AMM updates prices based on the trade.

---

### 4 · Call Ledger to execute (AMM → Ledger)

The **AMM** forwards the trade data and the `permitBlob` to the **Ledger**,  
which performs the actual fund transfer and ledger updates.

```solidity
ledger.executeBuyForUSDCWithPermit2(
    address trader,
    uint256 marketId,
    uint256 positionId,
    bool isBack,
    uint256 usdcIn,
    uint256 minTokensOut,
    bytes calldata permitBlob
) external returns (uint256 tOut);
```

---

### 5 · Pull Funds (Ledger → Trader)

Inside `DepositWithdrawLib.depositFromTraderWithPermit2(...)`,  
the **Ledger** decodes the permit and **pulls USDC** directly from the trader:

```solidity
IPermit2(s.permit2).permitTransferFrom(
    permit2Calldata,
    trader,
    address(this),
    amount
);
```

At this point, the Ledger holds the USDC.

---

### 6 · Deposit to Aave (Ledger → Aave)

Immediately after receiving the funds, the Ledger supplies USDC to **Aave** to generate yield:

```solidity
// --- Supply to Aave ---
...

aavePool.supply(address(s.usdc), amount, address(this), 0);

...
```

This converts the deposited USDC into **aUSDC** and updates internal accounting variables such as  
`totalValueLocked` and `totalFreeCollateral`.

---

### 7 · Apply Fee Skim (Ledger → Fee Receiver)

If protocol fees are enabled, the Ledger applies a skim on the Aave supply to deduct the fee before crediting collateral:

```solidity
// --- Optional protocol fee skim ---
uint256 recordedAmount = ProtocolFeeLib.skimOnAaveSupply(aReceived);
```


---

### 8 · Update Solvency (Ledger Internal)

The resulting `recordedAmount` is then credited to the appropriate market maker:

Once collateral is recorded, the Ledger adjusts its internal accounting to reflect the new exposure:

```solidity
// --- Update solvency state ---
updateTilt(marketId, positionId, isBack, tOut);
checkMinSharesNonNegative(mmId, marketId);
```

These checks ensure that all balances remain solvent (`minShares ≥ 0`)  

And we of course the addtionally redeemability constraint when we are using the internal synthetic credit

---

### 9 · Mint Instruction (Ledger → PositionToken1155)

After confirming solvency, the Ledger instructs the ERC-1155 contract to mint tokens for the trader:

```solidity
// --- Issue mint instruction ---
PositionToken1155.mintBackOrLay(
    trader,
    marketId,
    positionId,
    isBack,
    tOut
);
```


---

### 10 · ERC-1155 Minting (PositionToken1155 Contract)

Within the ERC-1155 contract, tokens are minted and assigned to the trader’s address:

```solidity
// --- Mint Back/Lay tokens to trader ---
_mint(
    trader,
    tokenId,   // unique Back/Lay token ID
    amount,    // number of tokens (tOut)
    ""
);
```

---

## Summary

| Step | Description | Responsible Contract |
|------|--------------|----------------------|
| 1 | Quote | AMM |
| 2 | Sign Permit | Trader |
| 3 | Execute Trade | AMM |
| 4–5 | Forward & Pull Funds | AMM → Ledger |
| 6 | Deposit to Aave | Ledger |
| 7 | Apply Fee Skim | Ledger |
| 8 | Update Solvency | Ledger |
| 9 | Mint Instruction | Ledger |
| 10 | ERC-1155 Minting | PositionToken1155 |


---

This expanded sequence reflects your repository’s logic,  
where **the Ledger** acts as the Permit2 spender, **pulls USDC**,  
**deposits to Aave with fee skimming**, ensures solvency,  
and mints ERC-1155 position tokens before the AMM updates market prices.
