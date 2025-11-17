
## 0 · Entry Point: AMM Calls on ` processBuy` on Ledger (AMM → Ledger)

AMM forwards trade params + `permitBlob` to the Ledger for fund movement and accounting.
```solidity
  ledger.processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited,
        bool usePermit2,
        bytes calldata permitBlob
    )
```

## 1 · Pull Funds (Ledger → USDC)
Ledger validates the permit and **pulls USDC**.
```solidity
IPermit2(s.permit2).permitTransferFrom(
    permit2Calldata, 
    trader, 
    address(this), 
    amount)
```

## 2 · Deposit to Aave  (Ledger → Aave)
Ledger supplies USDC to Aave, receiving interest‑bearing tokens.
```solidity
aavePool.supply(
    address(s.usdc), 
    amount, 
    address(this), 
    0
    )
```

## 3 · Apply Protocol Fee (Ledger Internal)
Skim fee from the received aTokens **before** crediting collateral.
```solidity
skimOnAaveSupply(aReceived);
```

## 4 · Credit collateral (Ledger Internal)

Credit collateral to the marketmaker

```solidity
// Credit real collateral
s.freeCollateral[mmId] += recordedAmount;
s.totalFreeCollateral  += recordedAmount;
s.totalValueLocked     += recordedAmount;
```

## 5 · Adjust Ledger Balances (Ledger Internal)

Adjust balances based on 

```solidity
 updateTilt(
    uint256 mmId,
     uint256 marketId, 
     uint256 positionId, 
     int128 delta // here this is -tOut
     )
```

## 6 · Enforce solvency (Ledger Internal)

```solidity
ensureSolvency(
    uint256 mmId, 
    uint256 marketId
    )
```

## 7 · Enforce Redeemability (Ledger Internal)
When synthetic credit (ISC) is in use, ensure **real** capital is sufficient against redeemable exposure.

```solidity
    if (redeemable > 0 && s.USDCSpent[mmId][marketId] < redeemable) {
        uint256 diff = uint256(redeemable - s.USDCSpent[mmId][marketId]);
        AllocateCapitalLib.allocate(mmId, marketId, diff);
        }
```


## 8 · Mint Instruction (Ledger → ERC‑1155)
Ledger authorizes mint of Back/Lay tokens to the trader.
```solidity
PositionToken1155.mint(
    address to,
    uint256 tokenId, 
    uint256 amount)
```

## 9 · ERC‑1155 Minting (Token Contract)
ERC‑1155 contract mints to the trader.
```solidity
_mint(
    trader, 
    tokenId, 
    tOut, 
    ""
    )
```

---