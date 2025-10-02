# Perpetual Market System Outline

This system enables continuous trading on positions like opinions in markets that never close.  
All positions are backed by USDC deposited into Aave to earn interest, ensuring full collateralization and providing yield to token holders.  

The current system is designed for not-pegged markets but small adjustments can be made to peg positions based on yield and outcomes.

---

## System Components

### Collateral Layer
USDC is deposited into Aave, where it earns interest.  

Markets use **iUSDC**.  

---

### Yield Layer
Manages interest from Aave:  

Yield flows directly to the treasury.  

---

### Governance Token Layer
The **Governance Token Layer** is concerned with the issuance and management of the governance token.  

- Handles issuance of governance tokens.  

---

### Governance Layer
The **Governance Layer** oversees how the protocol is governed.  

- Manages control of the protocol's received yield.  

---

### Ledger Layer
The **Ledger** is the accounting brain.  

- Tracks deposits and positions for each market maker.  
- Keeps everything fully collateralized.  
- Only stores numbers — tokens are minted or burned on demand.  
- Works for multi-winner markets.  

---

### TokenManager Layer
The **TokenManager** is the executor, controlled entirely by the Ledger.  

- Handles minting, burning, and transfers of all position tokens.  
- Cannot act independently — it only follows Ledger instructions.  
- Ensures circulating tokens always match ledger records.  

---

### Pricing Layer
The **Composite AMM (CAMM)** sets prices for all positions.  
 
- Provides constant liquidity using models such as LMSR or eliptical curve.
- Unified Liquidity across the whole composite market.
- CAMM can swap atomically between USDC ↔ tokens or token ↔ token.  

---

### Access Layer
1) Bespoke front end
2) **Uniswap V4 hooks**.  

- Trades route to the CAMM for pricing.  
- Settlement is handled by the Ledger and TokenManager.  
- Simple Front End or Uniswap interface for user

---

### Market Layer

Opinion markets, backed by iUSDC.  

---

## User Interactions

- Users buy or sell position tokens (e.g., “Back Liverpool”) via Uniswap V4 pools.  

---

## Market Maker Interactions

- Market Makers deposit USDC to recieve iUSDC
- Market Makers deposit iUSDC into the **Ledger**.  
- Their balances are stored as **virtual position shares**, not physical tokens.  
- Market Maker sets their own parameters for liquidity.
- Users buy tokens from the market maker's liquidity.
- Tokens are minted or burned on demand by the **TokenManager**, under Ledger control.  
- Market Makers collateral and effective positions always redeemable.   

- Market Maker rewards - market makers can be rewarded with Governance Token and USDC rewards

---

## Innovations

1) Native yield generation USDC deposits all stored in aave to generate yield

2) Lazy minting - liquidity providers dont need to mint any tokens, or manage splits and merges etc

3) Expanding markets - Ledger allows markets to expand to an indefinite number of positions

4) Flexible CAMMs - the market makers are not integral to the system so the liquidity provision and pricing dynamics can be adjusted

5) Eash Market Making - market makers can choose a CAMM and passive market make without actively managing splitting and merging

6) Clear auditting Ledger-Token Manager system ringfenced from the CAMMs. 



