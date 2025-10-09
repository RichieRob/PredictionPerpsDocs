# External Functions

## AMM-Hook Contract

The AMM-Hook contract interfaces with the `MarketMakerLedger` to facilitate trading of back and lay tokens for market makers (MMs) and users.

**Hook**: Called by the `PoolManager` for swap operations.  
**AMM**: Interfaces with the `MarketMakerLedger` to provide and manage tokens.

### afterSwap

#### Signature
```solidity
function afterSwap(
    address to,
    PoolKey calldata poolKey,
    SwapParams calldata poolParams,
    int256 delta,
    bytes calldata hookData
) external returns (bytes4, int256);
```

#### Details
##### Caller
`PoolManager`

##### Role
Entry point for buy and sell flows, coordinating with the `MarketMakerLedger`.

##### Buy Flow
1. Transfers USDC from `PoolManager` to Hook (`USDC.transferFrom`).
2. Computes output internally (`computeOutput`, not part of `MarketMakerLedger`).
3. Calls `MarketMakerLedger.processBuy(to, marketId, mmId, positionId, isBack, usdcIn, tokensOut, minUSDCDeposited)`, receiving `recordedUSDC`.
4. Returns `(selector, delta)` to `PoolManager`.

##### Sell Flow
1. Transfers `PositionToken` tokens from `PoolManager` to Hook (`PositionToken.transferFrom`).
2. Computes output internally (`computeOutput`, not part of `MarketMakerLedger`).
3. Calls `MarketMakerLedger.processSell(to, marketId, mmId, positionId, isBack, tokensIn, usdcOut)`.
4. Returns `(selector, delta)` to `PoolManager`.

---

### userBuy

#### Signature
```solidity
function userBuy(
    address to,
    address wantToken,
    uint256 minWant,
    uint256 usdcIn
) external;
```

#### Details
##### Caller
User

##### Role
Entry point for user-initiated buy flow, calls `MarketMakerLedger.processBuy` with appropriate `mmId`, `marketId`, `positionId`, and `isBack` derived from `wantToken`. Can mint tokens without USDC (`usdcIn = 0`).

##### Note
Assumes `wantToken` maps to a `PositionToken` (back or lay) for a specific `marketId` and `positionId`.

---

### userSell

#### Signature
```solidity
function userSell(
    address to,
    address dontWantToken,
    uint256 dontWantIn,
    uint256 minUsdcOut
) external;
```

#### Details
##### Caller
User

##### Role
Entry point for user-initiated sell flow, calls `MarketMakerLedger.processSell` with appropriate `mmId`, `marketId`, `positionId`, and `isBack` derived from `dontWantToken`. Can burn tokens without withdrawing USDC (`minUsdcOut = 0`).

##### Note
Assumes `dontWantToken` maps to a `PositionToken` (back or lay) for a specific `marketId` and `positionId`.

---

### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    uint256 mmId,
    address newAddress
) external;
```

#### Details
##### Caller
Hook Owner or MM

##### Role
Transfers all liquidity for an `mmId` to a new address by updating the `mmIdToAddress` mapping in the `MarketMakerLedger`.

##### Flow
1. Calls `MarketMakerLedger.transferLiquidity(mmId, newAddress)`.

##### Note
Restricted to the MM owning `mmId` or the Hook owner.

---

### depositUsdc

#### Signature
```solidity
function depositUsdc(
    uint256 mmId,
    uint256 amount,
    uint256 minUSDCDeposited
) external returns (uint256 recordedUSDC);
```

#### Details
##### Caller
Unrestricted

##### Role
Calls `MarketMakerLedger.deposit` with `mmId`. Increases Hook’s liquidity in the Ledger.

---

### withdrawUsdc

#### Signature
```solidity
function withdrawUsdc(
    uint256 mmId,
    uint256 amount
) external;
```

#### Details
##### Caller
Only Hook Owner or MM

##### Role
Calls `MarketMakerLedger.withdraw` with `mmId`. Decreases Hook’s liquidity in the Ledger.

---

## Ledger-Vault-TokenController Contract (`MarketMakerLedger`)

The `MarketMakerLedger` contract manages a vault for aUSDC balances, individualizes balances for each market maker (MM) by `mmId`, and controls `PositionToken` contracts for minting/burning tokens.

**Vault**: Tracks aUSDC balance supplied to Aave.  
**Ledger**: Manages individual MM balances (`mmCapitalization`, `freeCollateral`, `marketExposure`, `tilt`) by `mmId`.  
**TokenController**: Instructs `PositionToken` contracts to mint/burn tokens.

### registerMarketMaker

#### Signature
```solidity
function registerMarketMaker() external returns (uint256 mmId);
```

#### Details
##### Caller
Unrestricted (typically market makers)

##### Role
Registers a new market maker ID (`mmId`) for the caller’s address, enabling discrete liquidity pools.

##### Flow
1. Increments `nextMMId` and assigns `mmId` to `msg.sender` in `mmIdToAddress`.
2. Emits `MarketMakerRegistered` event.

---

### createMarket

#### Signature
```solidity
function createMarket(
    string memory name,
    string memory ticker
) external returns (uint256 marketId);
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

##### Note
Restricted to contract owner.

---

### createPosition

#### Signature
```solidity
function createPosition(
    uint256 marketId,
    string memory name,
    string memory ticker
) external returns (uint256 positionId);
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

##### Note
Restricted to contract owner.

---

### deposit

#### Signature
```solidity
function deposit(
    uint256 mmId,
    uint256 amount,
    uint256 minUSDCDeposited
) external returns (uint256 recordedUSDC);
```

#### Details
##### Caller
Unrestricted (typically market makers)

##### Role
Deposits USDC to the MM’s `freeCollateral` for `mmId`, supplies to Aave, updates capitalizations.

##### Flow
1. Transfers USDC from the MM’s address to contract (`USDC.transferFrom`).
2. Supplies USDC to Aave, records aUSDC received.
3. Ensures received aUSDC meets `minUSDCDeposited`.
4. Updates `freeCollateral[mmId]`, `mmCapitalization[mmId]`, `globalCapitalization`.
5. Emits `Deposited` event.
6. Returns `recordedUSDC`.

##### Note
Caller must approve the contract to spend USDC.

---

### withdraw

#### Signature
```solidity
function withdraw(
    uint256 mmId,
    uint256 amount
) external;
```

#### Details
##### Caller
MM or Hook Owner

##### Role
Withdraws USDC from the MM’s `freeCollateral` for `mmId`, pulls from Aave, updates capitalizations.

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender`.
2. Checks `freeCollateral[mmId]` and contract’s USDC balance.
3. Decrements `freeCollateral[mmId]`, `mmCapitalization[mmId]`, `globalCapitalization`.
4. Calls Aave’s `withdraw` to send USDC to MM.
5. Emits `Withdrawn` event.

---

### withdrawInterest

#### Signature
```solidity
function withdrawInterest() external;
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

---

### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    uint256 mmId,
    address newAddress
) external;
```

#### Details
##### Caller
MM or Owner

##### Role
Transfers all liquidity for an `mmId` to a new address by updating `mmIdToAddress`.

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender` or caller is owner.
2. Updates `mmIdToAddress[mmId]` to `newAddress`.
3. Emits `LiquidityTransferred` event.

---

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
) external returns (uint256 recordedUSDC);
```

#### Details
##### Caller
AMM-Hook

##### Role
Handles buy flow, depositing USDC to Aave and minting back or lay `PositionToken` tokens. Can mint tokens without USDC (`usdcIn = 0`).

##### Flow
1. Verifies `mmIdToAddress[mmId] == msg.sender`.
2. If `usdcIn > 0`, calls `deposit` with `mmId`, `usdcIn`, `minUSDCDeposited`.
3. For back tokens:
   - Calls `ensureSolvency`, updates `tilt` (negative), mints tokens.
4. For lay tokens:
   - Calls `ensureSolvency`, decrements `marketExposure[mmId]`, `mmCapitalization[mmId]`, `globalCapitalization`, updates `tilt` (positive), mints tokens.
5. Emits `Bought` and `TiltUpdated` events.
6. Returns `recordedUSDC`.

##### Note
Caller must approve USDC if `usdcIn > 0`.

---

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
) external;
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
4. If `usdcOut > 0`, calls `withdraw` with `mmId`, `usdcOut`.
5. Emits `Sold` and `TiltUpdated` events.

##### Note
Caller must approve `PositionToken` for burning.

---

### getPositionLiquidity

#### Signature
```solidity
function getPositionLiquidity(
    uint256 mmId,
    uint256 marketId,
    uint256 positionId
) external view returns (
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

##### Note
View function, no state changes.

---

### getMinTilt

#### Signature
```solidity
function getMinTilt(
    uint256 mmId,
    uint256 marketId
) external view returns (
    int128 minTilt,
    uint256 minPositionId
);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the minimum (most negative) tilt and its position ID for an MM in a market.

##### Note
View function, no state changes.

---

### getMMCapitalization

#### Signature
```solidity
function getMMCapitalization(
    uint256 mmId
) external view returns (uint256);
```

#### Details
##### Caller
Unrestricted

##### Role
Retrieves the MM’s capitalization (`mmCapitalization[mmId]`).

##### Note
View function, no state changes.

---

### getInterest

#### Signature
```solidity
function getInterest() external view returns (uint256);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns accrued interest (`aUSDC.balanceOf - globalCapitalization`).

##### Note
View function, no state changes.

---

### getMarkets

#### Signature
```solidity
function getMarkets() external view returns (uint256[] memory);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns an array of all market IDs.

##### Note
View function, no state changes.

---

### getMarketPositions

#### Signature
```solidity
function getMarketPositions(
    uint256 marketId
) external view returns (uint256[] memory);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns an array of position IDs for a given `marketId`.

##### Note
View function, no state changes.

---

### getMarketDetails

#### Signature
```solidity
function getMarketDetails(
    uint256 marketId
) external view returns (string memory name, string memory ticker);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the name and ticker for a given `marketId`.

##### Note
View function, no state changes.

---

### getPositionDetails

#### Signature
```solidity
function getPositionDetails(
    uint256 marketId,
    uint256 positionId
) external view returns (string memory name, string memory ticker, address backToken, address layToken);
```

#### Details
##### Caller
Unrestricted

##### Role
Returns the name, ticker, and back/lay token addresses for a given `marketId` and `positionId`.

##### Note
View function, no state changes.

---

## PositionToken Contract

`PositionToken` is an ERC20 contract deployed by `MarketMakerLedger` for each `(marketId, positionId)` pair (back and lay tokens). Access to minting and burning is restricted to the ledger.

### mint

#### Signature
```solidity
function mint(
    address to,
    uint256 amount
) external;
```

#### Details
##### Caller
`MarketMakerLedger` (via `processBuy`)

##### Role
Mints new `PositionToken` tokens.

##### Note
Restricted to `MarketMakerLedger` (via `onlyLedger` check).

---

### burnFrom

#### Signature
```solidity
function burnFrom(
    address from,
    uint256 amount
) external;
```

#### Details
##### Caller
`MarketMakerLedger` (via `processSell`)

##### Role
Burns `PositionToken` tokens from an account, checking allowance.

##### Note
Restricted to `MarketMakerLedger`. Caller must approve the ledger to burn tokens.

---

### Standard ERC20 Functions

#### transferFrom
##### Signature
```solidity
function transferFrom(
    address from,
    address to,
    uint256 amount
) external returns (bool);
```

#### Details
Standard ERC20 function for transferring tokens from one address to another.

---

#### balanceOf
##### Signature
```solidity
function balanceOf(
    address account
) external view returns (uint256);
```

#### Details
Standard ERC20 function to retrieve the token balance of an account.

---

#### totalSupply
##### Signature
```solidity
function totalSupply() external view returns (uint256);
```

#### Details
Standard ERC20 function to retrieve the total token supply.

---

#### approve
##### Signature
```solidity
function approve(
    address spender,
    uint256 amount
) external returns (bool);
```

#### Details
Standard ERC20 function to approve a spender to transfer tokens on behalf of the owner.

---

#### transfer
##### Signature
```solidity
function transfer(
    address to,
    uint256 amount
) external returns (bool);
```

#### Details
Standard ERC20 function to transfer tokens to a specified address.