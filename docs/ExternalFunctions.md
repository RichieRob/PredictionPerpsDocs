# External Function Specifications for Core Contracts

This document details the external function signatures for the core contracts: AMM-Hook, Ledger, and PositionToken. The Ledger deploys separate PositionToken contracts for each `(marketId, AMMId, tokenId)` pair, using ERC20-like semantics. The specifications align with the buy/sell flows and liquidity transfer processes.

## AMM-Hook Contract

The AMM-Hook contract interfaces with Uniswap V4's PoolManager, manages buy/sell flows, and handles liquidity transfers.

### afterSwap

#### Signature
```solidity
function afterSwap(
    address to,
    PoolKey calldata poolKey,
    SwapParams calldata swapParams,
    int256 delta,
    bytes calldata hookData
) external returns (bytes4, int256);
```

#### Details
- **Caller**: PoolManager (`msg.sender` is PoolManager)
- **Role**: Entry point for buy and sell flows. Initiates token transfers (USDC for buy, PositionToken for sell), calls Ledger's `readBalances`, invokes internal `submitBuy` or `submitSell`, and returns the function selector and delta to PoolManager.
- **Buy Flow**:
  1. Transfers USDC from PoolManager to Hook (`USDC.transferFrom`).
  2. Calls `Ledger.readBalances(marketId, AMMId)`.
  3. Computes output internally (`computeOutput`).
  4. Calls internal `submitBuy`, which calls `Ledger.processBuy(to, marketId, AMMId, tokenId, usdcIn, tokensOut)` with Hook as `msg.sender`.
  5. Returns `(selector, delta)` to PoolManager.
- **Sell Flow**:
  1. Transfers PositionTokens from PoolManager to Hook (`PositionToken.transferFrom`).
  2. Calls `Ledger.readBalances(marketId, AMMId)`.
  3. Computes output internally (`computeOutput`).
  4. Calls internal `submitSell`, which calls `Ledger.processSell(to, marketId, AMMId, tokenId, tokensIn, usdcOut)` with Hook as `msg.sender`.
  5. Returns `(selector, delta)` to PoolManager.
- **Note**: Ensures compliance with Uniswap V4's hook interface. Internal `computeOutput`, `submitBuy`, and `submitSell` are not exposed externally.

### submitBuy

#### Signature
```solidity
function submitBuy(
    address to,
    address tokenwanted,
    uint256 usdcIn,
    uint256 mintokensOut
) internal;
```

#### Details
- **Role**: Handles buy flow logic within the Hook, coordinating USDC transfer to Ledger and triggering token minting.
- **Flow**:
  1. Ensures USDC is transferred from Hook to Ledger (`USDC.transferFrom`).
  2. Calls `Ledger.processBuy(to, marketId, AMMId, tokenId, usdcIn, tokensOut)` with Hook as `msg.sender`.
- **Note**: Internal function, called within `afterSwap` during buy flow after AMM computations.

### submitSell

#### Signature
```solidity
function submitSell(
    address to,
    address tokenSold,
    uint256 tokensIn,
    uint256 minusdcOut
) internal;
```

#### Details
- **Role**: Handles sell flow logic within the Hook, coordinating PositionToken transfer to Ledger and triggering USDC withdrawal.
- **Flow**:
  1. Ensures PositionTokens are transferred from Hook to Ledger (`PositionToken.transferFrom`).
  2. Calls `Ledger.processSell(to, marketId, AMMId, tokenId, tokensIn, usdcOut)` with Hook as `msg.sender`.
- **Note**: Internal function, called within `afterSwap` during sell flow after AMM computations.

### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    uint256 marketId,
    address newAddress
) external;
```

#### Details
- **Caller**: Hook owner (`msg.sender` is owner)
- **Role**: Transfers liquidity ownership for `(marketId)` to a new address by calling `Ledger.transferLiquidity`.
- **Flow**:
  1. Calls `Ledger.transferLiquidity(newAddress, marketId, AMMId)` with Hook as `msg.sender`.
- **Note**: Restricted to Hook owner with access control (e.g., `onlyOwner` modifier, checking `msg.sender`). The sequence diagram's inclusion of `tokenId` is inconsistent with the signature, which only includes `marketId`.

## Ledger Contract

The Ledger tracks balances and ownership, routes mints/burns/withdrawals, and deploys multiple PositionToken contracts (one per `(marketId, AMMId, tokenId)`).

### readBalances

#### Signature
```solidity
function readBalances(
    uint256 marketId,
    uint256 AMMId
) external view;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook)
- **Role**: Retrieves balances for `(marketId, AMMId)` to support AMM computations in the Hook.
- **Note**: View function, no state changes. Return values are not specified but are used by Hook's `computeOutput`. Called with Hook as `msg.sender`.

### processBuy

#### Signature
```solidity
function processBuy(
    address to,
    uint256 marketId,
    uint256 AMMId,
    uint256 tokenId,
    uint256 usdcIn,
    uint256 tokensOut
) external;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook, via `submitBuy`- AMMID must match caller)
- **Role**: Handles buy flow by transferring USDC to Aave and minting PositionTokens.
- **Flow**:
  1. Receives USDC from Hook (`USDC.transferFrom`).
  2. Calls Aave's `supply(USDC, usdcIn, onBehalfOf = Ledger)` to deposit USDC.
  3. Receives aUSDC from Aave.
  4. Calls `updateBalances` internally to update state.
  5. Calls `PositionToken.mint(to, marketId, AMMId, tokenId, tokensOut)`.
- **Note**: Restricted to AMM-Hook with access control (e.g., `onlyHook` modifier, checking `msg.sender` is the Hook).

### processSell

#### Signature
```solidity
function processSell(
    address to,
    uint256 marketId,
    uint256 AMMId,
    uint256 tokenId,
    uint256 tokensIn,
    uint256 usdcOut
) external;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook, via `submitSell`AMMID must match caller)
- **Role**: Handles sell flow by burning PositionTokens and withdrawing USDC from Aave.
- **Flow**:
  1. Calls `PositionToken.burn(Hook, marketId, AMMId, tokenId, tokensIn)` to burn tokens.
  2. Calls Aave's `withdraw(USDC, usdcOut, to)` to withdraw USDC.
  3. Calls `updateBalances` internally to update state.
- **Note**: Restricted to AMM-Hook with access control (e.g., `onlyHook` modifier, checking `msg.sender` is the Hook).

### mint

#### Signature
```solidity
function mint(
    address to,
    uint256 marketId,
    uint256 AMMId,
    uint256 tokenId,
    uint256 amount
) external;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook, via `processBuy`)
- **Role**: Mints PositionTokens for the specified `(marketId, AMMId, tokenId)` by calling the corresponding PositionToken contract.
- **Flow**:
  1. Identifies the PositionToken contract for `(marketId, AMMId, tokenId)`.
  2. Calls `PositionToken.mint(to, amount)`.
- **Note**: Restricted to AMM-Hook with access control (e.g., `onlyHook` modifier, checking `msg.sender` is the Hook). The source document has `uint266 AMMId`, likely a typo (corrected to `uint256` for consistency).

### burn

#### Signature
```solidity
function burn(
    address from,
    uint256 marketId,
    uint256 AMMId,
    uint256 tokenId,
    uint256 amount
) external;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook, via `processSell`)
- **Role**: Burns PositionTokens for the specified `(marketId, AMMId, tokenId)` by calling the corresponding PositionToken contract.
- **Flow**:
  1. Identifies the PositionToken contract for `(marketId, AMMId, tokenId)`.
  2. Calls `PositionToken.burn(from, amount)`.
- **Note**: Restricted to AMM-Hook with access control (e.g., `onlyHook` modifier, checking `msg.sender` is the Hook). The source document has `uint266 AMMId`, likely a typo (corrected to `uint256` for consistency).

### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    address newAddress,
    uint256 marketId,
    uint256 AMMId
) external;
```

#### Details
- **Caller**: AMM-Hook (`msg.sender` is Hook)
- **Role**: Updates liquidity ownership for `(marketId, AMMId)` to the new address.
- **Flow**:
  1. Updates internal mapping to assign ownership to `newAddress`.
- **Note**: Restricted to AMM-Hook with access control (e.g., `onlyHook` modifier, checking `msg.sender` is the Hook). The sequence diagram's inclusion of `tokenId` is inconsistent with the signature.

## PositionToken Contract

PositionToken is an ERC20-like contract, with Ledger deploying separate instances for each `(marketId, AMMId, tokenId)`. Functions exclude `marketId`/`AMMId`/`tokenId` as they are implicit to the contract instance. Access is restricted (e.g., `onlyLedger` modifier for mint/burn).

### mint

#### Signature
```solidity
function mint(
    address to,
    uint256 amount
) external;
```

#### Details
- **Caller**: Ledger (`msg.sender` is Ledger, via `mint`)
- **Role**: Mints new PositionTokens to the recipient for the buy flow.
- **Note**: Restricted to Ledger with access control (e.g., `onlyLedger` modifier, checking `msg.sender` is the Ledger).

### burn

#### Signature
```solidity
function burn(
    address from,
    uint256 amount
) external;
```

#### Details
- **Caller**: Ledger (`msg.sender` is Ledger, via `burn`)
- **Role**: Burns PositionTokens from the sender for the sell flow.
- **Note**: Restricted to Ledger with access control (e.g., `onlyLedger` modifier, checking `msg.sender` is the Ledger).

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

##### Details
- **Caller**: AMM-Hook (sell flow, PoolManager to Hook)
- **Role**: Transfers PositionTokens (standard ERC20).
- **Note**: Used in sell flow to move tokens from PoolManager to Hook. `msg.sender` is typically the Hook.

#### balanceOf
##### Signature
```solidity
function balanceOf(
    address account
) external view returns (uint256);
```

##### Details
- **Caller**: AMM-Hook, Ledger
- **Role**: Queries token balance for an account.
- **Note**: Used for balance checks in buy/sell flows.

#### totalSupply
##### Signature
```solidity
function totalSupply() external view returns (uint256);
```

##### Details
- **Caller**: AMM-Hook, Ledger
- **Role**: Queries total token supply.
- **Note**: Used for AMM computations and balance checks.

#### approve
##### Signature
```solidity
function approve(
    address spender,
    uint256 amount
) external returns (bool);
```

##### Details
- **Caller**: Any user
- **Role**: Approves spender to transfer tokens (standard ERC20).
- **Note**: Used for interactions with PoolManager/Hook. `msg.sender` is the token owner.

#### transfer
##### Signature
```solidity
function transfer(
    address to,
    uint256 amount
) external returns (bool);
```

##### Details
- **Caller**: Any user
- **Role**: Direct token transfer (standard ERC20).
- **Note**: Used for general token transfers. `msg.sender` is the token owner.

#### Note
Each PositionToken contract is deployed per `(marketId, AMMId, tokenId)` by Ledger, so `marketId`/`AMMId`/`tokenId` are not needed in signatures. If using ERC1155 (single contract for all positions), functions would include an `id` parameter and use `safeTransferFrom`. Access controls (e.g., `onlyLedger` for mint/burn) ensure secure operations.