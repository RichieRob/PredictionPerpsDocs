# LSRM System Liquidity Provider (SLP)

## 1. Introduction
The **Logarithmic Market Scoring Rule (LMSR)**, introduced by Robin Hanson in 2003 (*Combinatorial Information Market Design*), is a market-making mechanism widely used in prediction markets.  

This document adapts LMSR into a **System Liquidity Provider (SLP)**, where the SLP is the sole liquidity source for two complementary tokens (Red and Green).  
The SLP mints new token pairs, prices them deterministically based on inventory.

Features of the SLP:

* Defined maximum liability  
* Deterministic, path-invariant pricing  
* Complementary pricing between Red and Green  
* Simple accounting and auditable state  

---

## 2. Key Concepts

- **Red Tokens ($R$)**: Represent one side of a binary market.  
- **Green Tokens ($G$)**: Represent the other side.  
- **Holdings ($h_R, h_G$)**: Balances of Red and Green held by the SLP.  
- **Pairs**: Always minted as 1 Red + 1 Green when USDC enters.  
- **Spot Price**: Determined directly from holdings:

  $$
  p_R = \frac{h_G}{h_R + h_G}, \quad p_G = \frac{h_R}{h_R + h_G}
  $$

  with the invariant:

  $$
  p_R + p_G = 1
  $$

---

## 3. Contract Roles

### System Liquidity Provider (SLP)
- Core AMM logic.  
- Holds Red and Green inventory.  
- Mints pairs when USDC is deposited.  
- Executes trades by selling one side against the other.  
- Updates balances to maintain deterministic pricing.  

### Red ERC20 Contract
- Standard ERC20 token for Red.  
- Minted and burned only by the SLP.  

### Green ERC20 Contract
- Standard ERC20 token for Green.  
- Minted and burned only by the SLP.  

---

## 4. Trade Routine

### 4.1 Market Initialization

An initial USDC deposit mints equal Red and Green tokens.  

Example: deposit \(F\) USDC  

\[
h_R = F
\]

\[
h_G = F
\]

Initial prices are symmetric:  

\[
p_R = p_G = 0.5
\]

---

### 4.2 Buying Red with USDC

1. User deposits \(D\) USDC.  

2. The SLP mints \(D\) Red and \(D\) Green into its inventory:  

\[
h_R' = h_R + D
\]

\[
h_G' = h_G + D
\]

Total post-mint inventory:  

\[
S = h_R' + h_G'
\]

\[
S = h_R + h_G + 2D
\]

3. From this fixed inventory, the user buys \(Q\) Red according to the cost function.  

4. Post Transaction balances update:  

\[
h_R = h_R' - Q
\]

\[
h_G = h_G'
\]

---

## 5. Deriving the Cost Function and the Quantity Function


### Step 1. Marginal price curve (from first principles)

We want to know the **price of Red** when the SLP has already sold \(q\) Red tokens.

- After deposit and minting, the **fixed total inventory** is

\[
S = h_R' + h_G'
\]

- If \(q\) Red tokens have been sold, the **remaining Red inventory** is

\[
h_R' - q
\]

- At that point, the **total remaining inventory** is

\[
S - q
\]

The pricing rule says that the price of Red is equal to the **proportion of Green in the remaining inventory**:

\[
p_R(q) = \frac{h_G'}{S - q}
\]

This ensures that as more Red is taken out (larger \(q\)), the denominator \(S - q\) shrinks, and thus the price of Red rises towards 1.


### Step 2. Small quantity cost

Now consider buying a **tiny quantity** \(\delta q\) of Red Tokens.  
The cost of those tokens is the price of them multiplied by the quantity of them

\[
\delta D = p_R(q) \cdot \delta q
\]

---

### Step 3. Quantity Function

Now if we buy a series of small quantities \(Q\) of Red tokens, we sum over all increments to find the price:

\[
D(Q) \approx \sum \, p_R(q) \cdot \delta q
\]

---

### Step 4. Limit to an integral

As \(\delta q \to 0\), the sum becomes an integral:

\[
D(Q) = \int_{0}^{Q} p_R(q)\,dq
\]

\[
D(Q) = \int_{0}^{Q} \frac{h_G'}{S - q}\,dq
\]

---

### Step 5. Evaluate the integral

\[
D(Q) = -\,h_G' \cdot \ln(S - q)\;\Big|_{0}^{Q}
\]

\[
D(Q) = h_G' \cdot \ln\!\left(\frac{S}{S - Q}\right)
\]


**Expanded in initial balances:**

\[
D(Q) = (h_G + D) \cdot \ln\!\left(\frac{\,h_R + h_G + 2D\,}{\,h_R + h_G + 2D - Q\,}\right)
\]

---

### Step 3. Tokens as a function of spend

Invert to solve for \(Q\):

\[
\frac{D(Q)}{h_G'} = \ln\!\left(\frac{S}{S - Q}\right)
\]

\[
e^{-D(Q)/h_G'} = \frac{S - Q}{S}
\]

\[
Q(D) = S \cdot \left(1 - e^{-D/h_G'}\right)
\]

**Restriction:**

\[
0 < Q < h_R'
\]

**Substituted form:**

\[
Q(D) = \big(h_R + h_G + 2D\big) \cdot \left(1 - e^{-\,D/(h_G + D)}\right)
\]

---

## 6. Properties

- **Deterministic Pricing**: Prices depend only on holdings.  
- **Finite Liability**: Max cost to drain one side is bounded.  
- **Complementary Markets**: Red and Green always sum to 1.  
- **Path Invariance**: Deposit and immediate withdraw returns the same USDC.  
- **Auditability**: State can be checked directly from ERC20 balances.  
