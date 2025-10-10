

# Ledger External Functions

This document outlines the external functions of the `MarketMakerLedger` contract, which manages a vault for aUSDC balances, individualizes balances for each market maker (MM) by `mmId`, and controls `PositionToken` contracts for minting/burning tokens.

## Market Maker Registration

### registerMarketMaker

#### Signature
```solidity
function registerMarketMaker()
    external
    returns (uint256 mmId);
```

#### Details
##### Caller
Unrestricted (typically market makers)

##### Role
Registers a new market maker ID (`mmId`) for the caller’s address, enabling discrete liquidity pools.

##### Flow
1. Increments `nextMMId` and assigns `mmId` to `msg.sender` in `mmIdToAddress`.
2. Emits `MarketMakerRegistered` event with the caller’s address and `mmId`.

##### Returns
- `mmId`: The assigned market maker ID.

## Admin Operations (Market/Position Creation)

### createMarket

#### Signature
```solidity
function createMarket(
    string memory name,
    string memory ticker
)
    external
    returns (uint256 marketId);
```

#### Details
##### Caller
Owner (restricted by `onlyOwner`)

##### Role
Creates a new market with a name and ticker, assigning a unique `marketId`.

##### Flow
1. Increments `nextMarketId` and stores `name` and `ticker` in storage.
2. Adds `marketId` to `allMarkets` array.
3. Emits `MarketCreated` event.

##### Returns
- `marketId`: The assigned market ID.

##### Note
Restricted to contract owner.

### createPosition

#### Signature
```solidity
function createPosition(
    uint256 marketId,
    string memory name,
    string memory ticker
)
    external
    returns (uint256 positionId);
```

#### Details
##### Caller
Owner (restricted by `onlyOwner`)

##### Role
Creates a new position in a market, deploying back and lay `PositionToken` contracts.

##### Flow
1. Verifies `marketId` exists.
2. Increments `nextPositionId[marketId]` and stores `name` and `ticker`.
3. Adds `positionId` to `marketPositions[marketId]` array.
4. Deploys `PositionToken` contracts for back and lay tokens.
5. Stores token addresses in `tokenAddresses`.
6. Emits `PositionCreated` event.

##### Returns
- `positionId`: The assigned position ID.

##### Note
Restricted to contract owner.

## Deposit/Withdraw Operations

### deposit

#### Signature
```solidity
function deposit(
    uint256 mmId,
    uint256 amount,
    uint256 minUSDCDeposited
)
    external
    returns (uint256 recordedUSDC);
```

#### Details
##### Caller
Unrestricted (typically market makers)

##### Role
Deposits USDC to the MM’s `freeCollateral` for `mmId`, supplies to Aave, and updates capitalizations.

##### Flow
1. Transfers USDC from the MM’s address to the contract (`USDC.transferFrom`).
2. Supplies USDC to Aave, records aUSDC received.
3. Ensures received aUSDC meets `minUSDCDeposited`.
4. Updates `freeCollateral[mmId]`, `mmCapitalization[mmId]`, and `globalCapitalization`.
5. Emits `Deposited` event with `mmId` and `recordedUSDC`.

##### Returns
- `recordedUSDC`: The actual aUSDC amount recorded.

##### Note
Caller must approve the contract to spend USDC.

### withdraw

#### Signature
```solidity
function withdraw(
    uint256 mmId,
    uint256 amount
)
    external;
```

#### Details
##### Caller
MM or Hook Owner

##### Role
Withdraws USDC from the MM’s `freeCollateral` for `mmId`, pulls from Aave, and updates capitalizations.

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender` or caller is owner.
2. Checks `freeCollateral[mmId]` and contract’s USDC balance.
3. Decrements `freeCollateral[mmId]`, `mmCapitalization[mmId]`, and `globalCapitalization`.
4. Calls Aave’s `withdraw` to send USDC to MM.
5. Emits `Withdrawn` event with `mmId` and `amount`.

### withdrawInterest

#### Signature
```solidity
function withdrawInterest()
    external;
```

#### Details
##### Caller
Owner (restricted by `onlyOwner`)

##### Role
Withdraws accrued interest (`aUSDC.balanceOf - globalCapitalization`) to the owner.

##### Flow
1. Calculates interest via `getInterest`.
2. Calls Aave’s `withdraw` to send USDC to owner.
3. Transfers USDC to owner.

## Trading Operations

### processBuy

#### Signature
```solidity
function processBuy(
    address to,
    uint256 marketId,
    uint256 mmId,
    uint256 positionId,
    bool isBack,
    uint256 usdcIn,
    uint256 tokensOut,
    uint256 minUSDCDeposited
)
    external
    returns (uint256 recordedUSDC);
```

#### Details
##### Caller
AMM-Hook

##### Role
Handles buy flow, depositing USDC to Aave and minting back or lay `PositionToken` tokens. Can mint tokens without USDC (`usdcIn = 0`).

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender`.
2. If `usdcIn > 0`, calls `deposit` with `mmId`, `usdcIn`, and `minUSDCDeposited`.
3. For back tokens:
   - Calls `ensureSolvency`, updates `tilt` (negative), mints tokens.
4. For lay tokens:
   - Calls `ensureSolvency`, decrements `marketExposure[mmId]`, `mmCapitalization[mmId]`, `globalCapitalization`, updates `tilt` (positive), mints tokens.
5. Emits `Bought` event with `mmId`, `marketId`, `positionId`, `isBack`, `tokensOut`, `usdcIn`, and `recordedUSDC`.
6. Emits `TiltUpdated` event with `mmId`, `marketId`, `positionId`, `freeCollateral`, `marketExposure`, and `newTilt`.

##### Returns
- `recordedUSDC`: The actual aUSDC amount recorded.

##### Note
Caller must approve USDC if `usdcIn > 0`.

### processSell

#### Signature
```solidity
function processSell(
    address to,
    uint256 marketId,
    uint256 mmId,
    uint256 positionId,
    bool isBack,
    uint256 tokensIn,
    uint256 usdcOut
)
    external;
```

#### Details
##### Caller
AMM-Hook

##### Role
Handles sell flow, burning back or lay `PositionToken` tokens and withdrawing USDC from Aave. Can burn tokens without withdrawing USDC (`usdcOut = 0`).

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender`.
2. For back tokens:
   - Updates `tilt` (positive), calls `deallocateExcess`, burns tokens.
3. For lay tokens:
   - Increments `marketExposure[mmId]`, `mmCapitalization[mmId]`, `globalCapitalization`, updates `tilt` (negative), calls `deallocateExcess`, burns tokens.
4. If `usdcOut > 0`, calls `withdraw` with `mmId` and `usdcOut`.
5. Emits `Sold` event with `mmId`, `marketId`, `positionId`, `isBack`, `tokensIn`, and `usdcOut`.
6. Emits `TiltUpdated` event with `mmId`, `marketId`, `positionId`, `freeCollateral`, `marketExposure`, and `newTilt`.

##### Note
Caller must approve `PositionToken` for burning.

## Liquidity Operations

### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    uint256 mmId,
    address newAddress
)
    external;
```

#### Details
##### Caller
MM or Owner

##### Role
Transfers all liquidity for an `mmId` to a new address by updating `mmIdToAddress`.

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender` or caller is owner.
2. Updates `mmIdToAddress[mmId]` to `newAddress`.
3. Emits `LiquidityTransferred` event with `mmId`, `msg.sender`, and `newAddress`.

## Getter Functions

### getPositionLiquidity

#### Signature
```solidity
function getPositionLiquidity(
    uint256 mmId,
    uint256 marketId,
    uint256 positionId
)
    external
    view
    returns (
        uint256 freeCollateral,
        uint256 marketExposure,
        int128 tilt
    );
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the MM’s liquidity details (`freeCollateral`, `marketExposure`, `tilt`) for a specific position.

##### Returns
- `freeCollateral`: The MM’s free USDC.
- `marketExposure`: The MM’s exposure in the market.
- `tilt`: The MM’s tilt for the position.

##### Note
View function, no state changes.

### getMinTilt

#### Signature
```solidity
function getMinTilt(
    uint256 mmId,
    uint256 marketId
)
    external
    view
    returns (
        int128 minTilt,
        uint256 minPositionId
    );
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the minimum (most negative) tilt and its position ID for an MM in a market.

##### Returns
- `minTilt`: The minimum (most negative) tilt value.
- `minPositionId`: The position ID with the minimum tilt.

##### Note
View function, no state changes.

### getMMCapitalization

#### Signature
```solidity
function getMMCapitalization(
    uint256 mmId
)
    external
    view
    returns (uint256);
```

#### Details
##### Caller
Unrestricted

##### Role
Retrieves the MM’s capitalization (`mmCapitalization[mmId]`).

##### Returns
- The MM’s capitalization for the given `mmId`.

##### Note
View function, no state changes.

### getInterest

#### Signature
```solidity
function getInterest()
    external
    view
    returns (uint256);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns accrued interest (`aUSDC.balanceOf - globalCapitalization`).

##### Returns
- The accrued interest amount.

##### Note
View function, no state changes.

### getMarkets

#### Signature
```solidity
function getMarkets()
    external
    view
    returns (uint256[] memory);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns an array of all market IDs.

##### Returns
- An array of all `marketId` values.

##### Note
View function, no state changes.

### getMarketPositions

#### Signature
```solidity
function getMarketPositions(
    uint256 marketId
)
    external
    view
    returns (uint256[] memory);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns an array of position IDs for a given `marketId`.

##### Returns
- An array of `positionId` values for the specified `marketId`.

##### Note
View function, no state changes.

### getMarketDetails

#### Signature
```solidity
function getMarketDetails(
    uint256 marketId
)
    external
    view
    returns (
        string memory name,
        string memory ticker
    );
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the name and ticker for a given `marketId`.

##### Returns
- `name`: The market’s name.
- `ticker`: The market’s ticker.

##### Note
View function, no state changes.

### getPositionDetails

#### Signature
```solidity
function getPositionDetails(
    uint256 marketId,
    uint256 positionId
)
    external
    view
    returns (
        string memory name,
        string memory ticker,
        address backToken,
        address layToken
    );
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the name, ticker, and back/lay token addresses for a given `marketId` and `positionId`.

##### Returns
- `name`: The position’s name.
- `ticker`: The position’s ticker.
- `backToken`: The address of the back `PositionToken`.
- `layToken`: The address of the lay `PositionToken`.

##### Note
View function, no state changes.