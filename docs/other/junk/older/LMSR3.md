# LSRM for Uniswap v4

## 1. Introduction
The **Logarithmic Market Scoring Rule (LMSR)**, introduced by Robin Hanson in 2003 (see: *Combinatorial Information Market Design*), is a market-making mechanism widely used in prediction markets.  

This document adapts LMSR into a **System Liquidity Provider (SLP)** designed for use with **Uniswap v4**, where the SLP sits behind two liquidity pools(with no liquidity) as a hook called with every transaction.

Features of the Uniswap v4 SLP

* Defined Risk
* Determinate Price
* Integrated complementary pricing between two pools
* Integrates with liquidity provided in any additional pools
* Easily add additional liquidity


---

## 2. Key Concepts

- **Red Tokens ($R$)**: Represent one side of a binary market.
- **Green Tokens ($G$)**: Represent the other side of a binary market.
- **Holdings ($h_R, h_G$)**: Balances of Red and Green held by the market contract.
- **Pairs**: Always minted as 1 Red + 1 Green when USDC enters the system.
- **Spot Price**: Determined directly from holdings:

  $$
  p_R = \frac{h_G}{h_R + h_G}, \quad p_G = \frac{h_R}{h_R + h_G}
  $$

  Prices are always complementary:

  $$
  p_R + p_G = 1
  $$

---

## 3. Contract Roles

### System Liquidity Provider (SLP)
  - Acts as the interface for traders to swap to and from USDC to market tokens.
  - Holds Red and Green tokens as inventory.
  - Computes trade amounts and transfers Red or Green tokens to traders based on the cost function.

### Market Controller
  - Manages the Red ERC20 Contract and Green ERC20 Contract.
  - Custodies vUSDC received from the Treasury for internal accounting.
  - Mints Red and Green token pairs on deposits and sends them to the SLP.
  - Burns Red and Green token pairs on redemptions and redeems vUSDC for USDC from treasury.

### Red ERC20 Contract
  - Standard ERC20 contract representing Red tokens.
  - Controlled by the Market Controller for minting and burning.

### Green ERC20 Contract
  - Standard ERC20 contract representing Green tokens.
  - Controlled by the Market Controller for minting and burning.

### Treasury (vUSDC controller)
  - Custodies all USDC, depositing it into Aave to earn yield (aUSDC).
  - Mints vUSDC via the vUSDC Contract to track deposited USDC.
  - Sends vUSDC to the Market Controller during the USDC and token flow routine.
  - Handles withdrawals from Aave when redemptions occur.

### vUSDC Contract
  - Receipt token held by the Market Controller to facilitate internal accounting of USDC deposited in Aave.
  - Minted and managed by the Treasury.
  - Pegged 1:1 to USDC.

---

## 4. Token Flow implementation with easy accounting and auditing


### 4.1 USDC and Token Flow Routine

This routine describes how USDC moves up the chain and how vUSDC and token pairs move down:

#### USDC Upward Flow
   - USDC is sent from the caller (market initiator or trader) to the SLP.
   - SLP forwards the USDC to the Market Controller.
   - Market Controller sends the USDC to the Treasury.
   - Treasury deposits the USDC into Aave, receiving aUSDC (yield-bearing).

#### vUSDC and Token Pairs Downward Flow
   - Treasury mints vUSDC (a receipt token pegged 1:1 to USDC) via the vUSDC Contract and sends it to the Market Controller.
   - Market Controller retains vUSDC for internal accounting and mints an equal amount of Red and Green token pairs via the Red ERC20 Contract and Green ERC20 Contract.
   - Market Controller sends the Red and Green token pairs to the SLP.
   - SLP holds the token pairs as inventory for trading.

This routine ensures that all USDC is custodied in Aave and receipts are passed down the chain.

### 4.2 Market Initiation Sequence

The market is initialized with an initial funding amount to bootstrap liquidity:

1. The SLP is called with an `initialFund(uint)` function, specifying the initial USDC amount.
2. The SLP pulls the specified USDC from the caller.
3. The USDC and token flow routine is executed:
    - USDC is sent from SLP to Market Controller, then to Treasury, and deposited into Aave.
    - Treasury mints vUSDC and sends it to the Market Controller.
     - Market Controller mints Red and Green token pairs and sends them to the SLP.
4. The SLP is now initiated with Red and Green tokens in its inventory, ready for trading.

### 4.3 Trading Sequence

When a trader deposits $D$ USDC to trade:

1. The trader sends $D$ USDC to the SLP.
2. The USDC and token flow routine is executed:
    - USDC is sent from SLP to Market Controller, then to Treasury, and deposited into Aave.
     - Treasury mints $D$ vUSDC and sends it to the Market Controller.
     - Market Controller mints $D$ Red and $D$ Green tokens and sends them to the SLP.
3. The SLP computes the number of Red (or Green) tokens to send to the trader using the cost function.
4. Remaining tokens are left in the SLP’s inventory, ensuring balances match the pricing function.

This guarantees:

- **Path invariance**: Immediate deposit/withdraw cycles return the same USDC.  
- **Finite liability**: The Market Controller always has sufficient reserves.  
- **Determinate state**: Prices depend only on holdings. 
- **Auditable**: Values of each contract clear.

---



## 5. Pricing and Trade Math (with Derivation)

We’ll use **Red (R)** and **Green (G)** as the two sides of the market.

**SLP Starting Red Balance**

\[
h_R
\]

**SLP Starting Green Balance**

\[
h_G
\]

**Red Price**

\[
p_R = \frac{h_G}{h_R + h_G},
\]

**Green Price**

\[
p_G = \frac{h_R}{h_R + h_G},
\]

**Combined Price Invariant**

\[
p_R + p_G = 1.
\]

When a user **buys Red** with a deposit of \(D\) USDC, the SLP uses the USDC to mint \(D\) new pairs:

**SLP Post-Mint Red Balance**

\[
h_R' = h_R + D,
\]

**SLP Post-Mint Green Balance**

\[
h_G' = h_G + D,
\]

**SLP Post-Mint Combined Token Balance**

\[
S = h_R' + h_G' = (h_R + D) + (h_G + D).
\]

---

### Step 1. Marginal price curve

The instantaneous (marginal) price of Red, when selling \(q\) units from inventory, is given by:

\[
p_R(q) = \frac{h_G'}{S - q}
\]

where:

- \(h_G' = h_G + D\) (post-mint Green)  
- \(S = h_R + h_G + 2D\) (post-mint total)

---

### Step 2. Total spend

To compute the **total spend** for buying \(Q\) Red tokens, integrate the marginal price along the fill path:

\[
D(Q) = \int_{0}^{Q} p_R(q)\,dq
\]

\[
D(Q) = \int_{0}^{Q} \frac{h_G'}{S - q}\,dq
\]

\[
D(Q) = -\,h_G' \cdot \ln(S - q)\;\Big|_{0}^{Q}
\]

\[
D(Q) = h_G' \cdot \ln\!\left(\frac{S}{S - Q}\right)
\]

Expanding in terms of the initial balances:

\[
D(Q) = (h_G + D) \cdot \ln\!\left(\frac{\,h_R + h_G + 2D\,}{\,h_R + h_G + 2D - Q\,}\right)
\]

---

### Step 3. Tokens as a function of spend

We now invert the above relation to solve for \(Q\) in terms of \(D\):

\[
D(Q) = h_G' \cdot \ln\!\left(\frac{S}{S - Q}\right)
\]

\[
\frac{D(Q)}{h_G'} = \ln\!\left(\frac{S}{S - Q}\right)
\]

\[
e^{-D(Q)/h_G'} = \frac{S - Q}{S}
\]

\[
Q(D) = S \cdot \left(1 - e^{-D/h_G'}\right)
\]

with the natural restriction

\[
0 < Q < h_R'
\]

Substituting the intial variables gives

\[
Q(D) = \big(h_R + h_G + 2D\big) \cdot \left(1 - e^{-\,D/(h_G + D)}\right)
\]

---
