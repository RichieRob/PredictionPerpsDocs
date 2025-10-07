# Contracts
---

## Core Protocol

### Vault
- Holds aUSDC received from the Lending Controller.
- Keeps a record of the Ledger's deposits (principal) for tracking.
- Allows the Revenue Bucket to withdraw the interest generated from aUSDC.
- Sends USDC to and receives USDC from the Lending Controller.
- Receives USDC from the Ledger.
- Sends USDC to the Ledger.
- Receives aUSDC from the Lending Controller.
- Sends aUSDC to the Lending Controller to redeem USDC.

### Revenue Bucket
- Collects and manages interest generated from aUSDC deposits.
- Withdraws interest from the Vault.
- Distributes profits under Governance control.

### Lending Controller
- Deposits USDC into Aave to earn interest.
- Withdraws USDC from Aave when needed.
- Sends USDC to the Vault.
- Receives USDC from the Vault.
- Sends aUSDC to the Vault.
- Receives aUSDC from the Vault (for redemption purposes).

### Ledger
The **Ledger** manages the accounting system with these core functions:
- Records USDC deposits for each market maker, tracking their principal.
- Ensures all positions remain fully collateralized.
- Triggers TokenManager to mint or burn position tokens only on demand.
- Provides a transparent audit trail of all transactions.
- Sends USDC to the Vault, which forwards it to the Lending Controller for Aave deposit.
- Receives USDC from the Vault to reconcile deposit records after withdrawals or adjustments.

### TokenManager
The **TokenManager** executes Ledger commands.
- Mints, burns, and transfers position tokens.
- Operates only under Ledger instructions.

### Position Tokens
- Represent user positions within the system.
- Minted or burned on demand by the TokenManager.
- Implemented as ERC20 tokens.

---

## Periphery Contracts

### Uniswap V4 Hook
- Directs USDC flow via the PoolManager.
- Routes trades to the CAMM for pricing and settlement.

### AMM
- Implements the Composite AMM (CAMM) for pricing and liquidity.
- Provides constant liquidity using LMSR or elliptical curve models.
- Enables atomic swaps between USDC ↔ tokens or token ↔ token.

---

## Third Party Contracts

### Uniswap PoolManager
- Manages liquidity pools.
- Directs USDC flow based on Uniswap V4 Hook instructions.

### Aave
- Accepts USDC deposits and generates aUSDC with interest.
- Returns USDC to the Lending Controller upon withdrawal.

### USDC
- Serves as the stablecoin for collateral and flow.

### aUSDC
- Aave’s interest-bearing version of USDC, sent to the Vault.