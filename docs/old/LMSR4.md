# LSRM System Liquidity Provider (SLP)

## 1. Introduction
The **Logarithmic Market Scoring Rule (LMSR)**, introduced by Robin Hanson in 2003 (*Combinatorial Information Market Design*), is a market-making mechanism which is used in some prediction markets.  

This document adapts LMSR into a **System Liquidity Provider (SLP)**, where the SLP is the a liquidity source for two complementary tokens (Red and Green). 

The SLP mints new token pairs, prices them deterministically based on its inventory.

The SLP is designed to feature as part of a Uniswap V4 hook, so it can dovetail with additional liquidity pools, and give a defined complementary price of Red and Green tokens.

This document considers markets as binary, but there are no doubt extensions that can be made for multi directional markets.

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

The trader has \(D\) USDC and wants Red tokens.

1. **Inventory preparation (accounting step).**  
   The SLP mints \(D\) Red and \(D\) Green **to itself** to set a fixed pricing inventory.

\[
h_R' = h_R + D
\]

\[
h_G' = h_G + D
\]

\[
S = h_R' + h_G'
\]

\[
S = h_R + h_G + 2D
\]

2. **Trade execution against the fixed inventory.**  
   The trader spends all \(D\) to buy \(Q\) Red according to the cost function.


3. **Post-trade balances.**

\[
h_R = h_R' - Q
\]

\[
h_G = h_G'
\]



---

## 5. Deriving the Cost Function and the Quantity Function


### Step 1. Marginal price curve (from first principles)

We want to know how the **price of Red** changes as the user buys red tokens.

That is when a user buys Q tokens, what is the price of each unit.

That is the price when the SLP has already sold \(q\) Red tokens.


- The first step of the process is that the SLP mints additional tokens equal to the D USDC which the user is supplying to buy tokens. This now becomes the **total inventory** S

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

\[
\lim_{q \uparrow h_R'} (S - q) = h_G'
\]

\[
\lim_{q \uparrow h_R'} p_R(q) = 1
\]


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


**Substituting for initial varibles**

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

- **Deterministic Pricing**: Prices depend only on SLP token holdings.  
- **Finite Liability**:  Liability is simply the initial funding of the SLP.
- **Fixed Complementary Pricing**: Red and Green always sum to 1.  
- **Path Invariance**: Deposit and immediate withdraw returns the same USDC.  


## 7. Extending to three position market

### 7.1 Market Initialization

An initial USDC deposit mints equal R G and B tokens.  

Example: deposit \(F\) USDC  

\[
h_R = F
\]

\[
h_G = F
\]

\[
h_B = F
\]

A subsequent user deposit of \(D\) USDC mints \(D\) of each into SLP inventory.

\[
h_R' = h_R + D
\]

\[
h_G' = h_G + D
\]

\[
h_B' = h_B + D
\]

\[
S = h_R' + h_G' + h_B'
\]

### 7.2 Spot Prices (pre-trade)

\[
S_0 = h_R + h_G + h_B
\]

\[
p_R = \frac{h_G + h_B}{2 S_0}
\]

\[
p_G = \frac{h_R + h_B}{2 S_0}
\]

\[
p_B = \frac{h_R + h_G}{2 S_0}
\]

\[
p_R + p_G + p_B = 1
\]

### 7.3 Spot Prices (mid-trade)

\[
S = h_R' + h_G' + h_B'
\]

\[
p_R = \frac{h_G' + h_B'}{2 S}
\]

\[
p_G = \frac{h_R' + h_B'}{2 S}
\]

\[
p_B = \frac{h_R' + h_G'}{2 S}
\]

\[
p_R + p_G + p_B = 1
\]


### 7.3 Buying \(R\)

\[
p_R(q) = \frac{h_G' + h_B'}{2\,(S - q)}
\]

\[
D_R(Q) = \int_{0}^{Q} p_R(q)\,dq
\]

\[
D_R(Q) = \frac{h_G' + h_B'}{2}\,\ln\!\left(\frac{S}{S - Q}\right)
\]

\[
Q_R(x) = S\left(1 - e^{-\,\frac{2x}{\,h_G' + h_B'\,}}\right)
\]

**Substituting for initial variables**

\[
h_G' + h_B' = h_G + h_B + 2D
\]

\[
S = h_R + h_G + h_B + 3D
\]

\[
D_R(Q) = \frac{h_G + h_B + 2D}{2}\,\ln\!\left(\frac{h_R + h_G + h_B + 3D}{h_R + h_G + h_B + 3D - Q}\right)
\]

\[
Q_R(x) = \big(h_R + h_G + h_B + 3D\big)\left(1 - e^{-\,\frac{2x}{\,h_G + h_B + 2D\,}}\right)
\]

**By symmetry**

\[
D_G(Q) = \frac{h_R' + h_B'}{2}\,\ln\!\left(\frac{S}{S - Q}\right)
\]

\[
Q_G(x) = S\left(1 - e^{-\,\frac{2x}{\,h_R' + h_B'\,}}\right)
\]

\[
D_B(Q) = \frac{h_R' + h_G'}{2}\,\ln\!\left(\frac{S}{S - Q}\right)
\]

\[
Q_B(x) = S\left(1 - e^{-\,\frac{2x}{\,h_R' + h_G'\,}}\right)
\]

---


## 8. General \(n\)-Outcome Market

### 8.1 Market Initialization

An initial USDC deposit mints equal amounts of all \(n\) outcome tokens \(X_1,\dots,X_n\).  

Example: deposit \(F\) USDC  

\[
h_i = F \quad \text{for } i \in \{1,\dots,n\}
\]

A subsequent user deposit of \(D\) USDC mints \(D\) of each into SLP inventory.

\[
h_i' = h_i + D \quad \text{for } i \in \{1,\dots,n\}
\]

\[
S = \sum_{i=1}^{n} h_i'
\]


### Spot Prices (pre-trade)

\[
S_0 = \sum_{i=1}^{n} h_i
\]

\[
p_i = \frac{S_0 - h_i}{(n-1)\,S_0}
\]

\[
\sum_{i=1}^{n} p_i = 1
\]

### Spot Prices (mid-trade)

\[
S = \sum_{i=1}^{n} h_i'
\]

\[
p_i = \frac{S - h_i'}{(n-1)\,S}
\]

\[
\sum_{i=1}^{n} p_i = 1
\]


### Buying outcome \(k\)

\[
p_k(q) = \frac{S - h_k'}{(n-1)\,(S - q)}
\]

\[
D_k(Q) = \int_{0}^{Q} p_k(q)\,dq
\]

\[
D_k(Q) = \frac{S - h_k'}{\,n-1\,}\;\ln\!\left(\frac{S}{S - Q}\right)
\]

\[
Q_k(x) = S\left(1 - e^{-\,\frac{(n-1)\,x}{\,S - h_k'\,}}\right)
\]

**Expanded in initial balances**

\[
S = \sum_{i=1}^{n} h_i + nD
\]

\[
S - h_k' = \sum_{j\neq k} h_j + (n-1)D
\]

\[
p_k = \frac{\sum_{j\neq k} h_j + (n-1)D}{(n-1)\left(\sum_{i=1}^{n} h_i + nD\right)}
\]

\[
D_k(Q) = \frac{\sum_{j\neq k} h_j + (n-1)D}{\,n-1\,}\;\ln\!\left(\frac{\sum_{i=1}^{n} h_i + nD}{\sum_{i=1}^{n} h_i + nD - Q}\right)
\]

\[
Q_k(x) = \left(\sum_{i=1}^{n} h_i + nD\right)\left(1 - \exp\!\left[-\,\frac{(n-1)\,x}{\sum_{j\neq k} h_j + (n-1)D}\right]\right)
\]

