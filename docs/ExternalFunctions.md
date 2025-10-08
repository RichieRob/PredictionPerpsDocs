# External Functions


## AMM-Hook Contract

The AMM-Hook contract 

Hook - called by pool manager

AMM - interfaces with Ledger to provide tokens

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
##### Caller
PoolManager

##### Role
Entry point for buy and sell flows

##### Buy Flow
1. Transfers USDC from PoolManager to Hook (`USDC.transferFrom`).
2. Calls `Ledger.readBalances(marketId, AMMId)`.
3. Computes output internally (`computeOutput`).
4. Calls `Ledger.processBuy(to, marketId, AMMId, tokenId, usdcIn, tokensOut)` .
5. Returns `(selector, delta)` to PoolManager.

##### Sell Flow
1. Transfers PositionTokens from PoolManager to Hook (`PositionToken.transferFrom`).
2. Calls `Ledger.readBalances(marketId, AMMId)`.
3. Computes output internally (`computeOutput`).
4. Calls `Ledger.processSell(to, marketId, AMMId, tokenId, tokensIn, usdcOut)` 
5. Returns `(selector, delta)` to PoolManager.


---

### userBuy
#### Signature
```solidity
function userBuy(
    address to,
    address wantToken,
    uint256 minwant,
    uint256 usdcIn
) external 
```
#### Details
##### Caller
User

##### Role
Entry point for buy flow - user call

---

### userSell
#### Signature
```solidity
function userSell(
    address to,
    address dontwantToken,
    uint256 dontwantIn,
    uint256 minUsdcOut
) external 
```
#### Details
##### Caller
User

##### Role
Entry point for sell flow - user call

---



### transferLiquidity

#### Signature
```solidity
function transferLiquidity(
    uint256 marketId,
    address newAddress
) external;
```

#### Details
##### Caller
Hook owner 

##### Role
Transfers liquidity ownership for `(marketId)` to a new address by calling `Ledger.transferLiquidity`.

##### Flow
1. Calls `Ledger.transferLiquidity(newAddress, marketId, AMMId)` 

##### Note
Restricted to Hook owner

---

### depositUsdc
#### Signature
```solidity
function depositUsdc(
    uint256 amount
) external 
```
#### Details
##### Caller
unrestricted

##### Role
increase Hook balance

#### Notes
Can be call to process buy on the ledger with 0 tokens required?

---

### withdrawUsdc
#### Signature
```solidity
function withdrawUsdc(
    uint256 amount
) external 
```
#### Details
##### Caller
only Hook Owner

##### Role
decrease Hook balance

#### Notes
Can be call to process sell on the ledger with 0 tokens deposited?

---

### depositTokens
#### Signature
```solidity
function depositTokens(
    uint256 amount,
    address token
) external 
```
#### Details
##### Caller
only Hook Owner

##### Role
increase Hook Token balance

#### Notes
Can be call to process sell on the ledger with 0 usdc required?

---


### withdrawTokens
#### Signature
```solidity
function withdrawTokens(
    uint256 amount,
    address token
) external 
```
#### Details
##### Caller
only Hook Owner

##### Role
decrease Hook Token balance

#### Notes
Can be call to process buy on the ledger with 0 usdc deposited?

---


## Ledger-Vault-TokenController Contract

Vault - aUSDC balance of system

Ledger - individualised balances of each MM

Ledger - maps tokenid to PositionToken Contracts

TokenController - Instructs PositionToken Contracts


### readBalances

#### Signature
```solidity
function readBalances(
    uint256 marketId,
    uint256 AMMId
) external view;
```

#### Details
##### Caller
AMM-Hook

##### Role
Retrieves balances for `(marketId, AMMId)` returns an array. 

##### Note
View function, no state changes. 

---

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
##### Caller
AMM-Hook 

##### Role
Handles buy flow - updates ledger - transferring USDC to Aave - mints PositionTokens.

##### Flow
1. Receives USDC from Hook (`USDC.transferFrom`).
2. Calls Aave's `supply(USDC, usdcIn, onBehalfOf = Ledger)` to deposit USDC.
3. Receives aUSDC from Aave.
4. Calls `updateBalances` internally to update state.
5. Calls `PositionToken.mint(to, marketId, AMMId, tokenId, tokensOut)`.

##### Note
Restricted AMMId must match Hook

---

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
##### Caller
AMM-Hook

##### Role
Handles sell flow - updates ledger - pulling USDC from Aave - burning PositionTokens.

##### Flow
1. Calls `PositionToken.burn(Hook, marketId, AMMId, tokenId, tokensIn)` to burn tokens.
2. Calls Aave's `withdraw(USDC, usdcOut, to)` to withdraw USDC.
3. Calls `updateBalances` internally to update state.

##### Note
Restricted AMMId must match Hook


---

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
##### Caller
AMM-Hook

##### Role
Updates liquidity ownership for `(marketId, AMMId)` to the new address.

##### Flow
1. Updates internal mapping to assign ownership to `newAddress`.

##### Note
Restricted AMMId must match Hook

---

## PositionToken Contract

PositionToken is an ERC20 contract, with Ledger deploying separate instances for each `(marketId, tokenId)`.  Access is restricted (e.g., `onlyLedger` modifier for mint/burn).

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
Ledger (via `processBuy`)

##### Role
Mints new PositionTokens 

##### Note
Restricted to Ledger

---

### burn

#### Signature
```solidity
function burn(
    address from,
    uint256 amount
) external;
```

#### Details
##### Caller
Ledger ( via `processSell`)

##### Role
Burns PositionTokens 

##### Note
Restricted to Ledger

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