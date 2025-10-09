    # LMSR System Liquidity Provider (SLP)

    ## 1. Introduction
    The **Logarithmic Market Scoring Rule (LMSR)**, introduced by Robin Hanson (2003, *Combinatorial Information Market Design*), is a closed-form automated market-making mechanism. It provides path-independent pricing and bounded liability, and has been used in several real-world prediction markets (e.g. Iowa Electronic Markets, Gnosis).  

    This document shows how LMSR is adapted into a **System Liquidity Provider (SLP)** for a **binary market** with two complementary tokens: **Red (R)** and **Green (G)**.  

    The SLP is not the market itself. The **Market Controller** handles only *splitting* and *merging*:  

    - **Split**: 1 USDC → (1 R + 1 G).  
    - **Merge**: (1 R + 1 G) → 1 USDC.  

    The **SLP** sits on top of this controller:  

    - It acquires tokens from the Market Controller using USDC.  
    - It prices and trades tokens deterministically using LMSR formulas.  
    - It can be deployed as a Uniswap v4 hook, alongside other liquidity sources.  

    **Key features:**  

    * Bounded maximum liability.  
    * Deterministic, path-independent pricing.  
    * Complementary prices (\(p_R + p_G = 1\)).  
    * Transparent state (balances are auditable).  

    ---

    ## 2. Key Concepts (Binary Market)

    - **Red Tokens (\(R\))**: One outcome.  
    - **Green Tokens (\(G\))**: The complementary outcome.  
    - **Holdings**:  
    - \(h_R\): balance of Red tokens held by the SLP.  
    - \(h_G\): balance of Green tokens held by the SLP.  
    - **LMSR Liquidity Parameter (\(b\))**: Controls depth of the market and maximum liability.  
    - **Market Controller**: Issues and redeems bundles of \(R+G\) against USDC.  
    - **System Liquidity Provider (SLP)**: Uses LMSR maths to trade \(R\) and \(G\) with users.  

    ---

    ## 3. Funding & Parameterization

    ### 3.1 Bounded Loss in LMSR
    Hanson proved that in an LMSR with \(n\) outcomes, the market maker’s **worst-case loss** is:

    \[
    L_{\max} = b \cdot \ln n.
    \]

    For a **binary market** (\(n=2\)):

    \[
    L_{\max} = b \cdot \ln 2.
    \]

    ---

    ### 3.2 Funding the SLP
    We assume the SLP begins by providing **\(F\) USDC** into the Market Controller. This \(F\) is the maximum loss the SLP is willing to risk. Therefore:

    \[
    F = b \cdot \ln 2,
    \]

    which implies

    \[
    b = \frac{F}{\ln 2}.
    \]

    ---

    ### 3.3 Initialization
    1. **Deposit:** SLP deposits \(F\) USDC into the Market Controller.  
    2. **Split:** Controller issues \(F\) Red + \(F\) Green to the SLP.  
    3. **Set \(b\):**

    \[
    b = \tfrac{F}{\ln 2}.
    \]  

    4. **Initial prices:** 

    \[
    p_R = p_G = 0.5.
    \]  

    ---

    ## 4. LMSR Pricing (from Hanson)

    The **LMSR cost function** is:  

    \[
    C(h_R, h_G) = b \cdot \ln\!\left(e^{h_R/b} + e^{h_G/b}\right).
    \]

    - **Spot price of Red**:  

    \[
    p_R = \frac{e^{h_R/b}}{e^{h_R/b} + e^{h_G/b}}
    \]

    - **Spot price of Green**:  

    \[
    p_G = \frac{e^{h_G/b}}{e^{h_R/b} + e^{h_G/b}}
    \]

    - Invariant:  

    \[
    p_R + p_G = 1
    \]

    ---

    ## 5. Trading Logic

    ### 5.1 Buying Red

    The cost to acquire \(Q\) Red tokens is:

    \[
    D(Q) = C(h_R + Q, h_G) - C(h_R, h_G).
    \]

    Given spend \(D\), the number of Red tokens received is:

    \[
    Q(D) = b \cdot \ln\!\left(\frac{e^{D/b} - (1 - p_{R,0})}{p_{R,0}}\right),
    \]

    where \(p_{R,0}\) is the pre-trade Red price.

    **Inventory update:**

    \[
    h_R \gets h_R + Q(D), 
    \]

    \[
    h_G \text{ unchanged.}
    \]

    ---

    ### 5.2 Buying Green

    By symmetry:

    \[
    D(Q) = C(h_R, h_G + Q) - C(h_R, h_G).
    \]

    \[
    Q(D) = b \cdot \ln\!\left(\frac{e^{D/b} - (1 - p_{G,0})}{p_{G,0}}\right).
    \]

    **Inventory update:**

    \[
    h_G \gets h_G + Q(D).
    \]

    ---

    ## 6. Merge and Split Logic

    - **Split (Controller)**: Trader deposits USDC → Controller issues (1 R + 1 G).  
    - The SLP may use this to increase inventory before trading.  

    - **Merge (Controller)**: Trader returns (1 R + 1 G) → Controller redeems 1 USDC.  
    - Provides a canonical redemption path.  
    - Ensures outcome tokens cannot inflate unchecked.  

    ---

    ## 7. Properties

    - **Bounded loss:** Worst-case liability is exactly the initial funding \(F\).  
    - **No idle USDC in SLP:** All USDC sits in the Market Controller, convertible through split/merge.  
    - **Composable:** SLP is just one LP — others may coexist.  
    - **Deterministic:** Prices depend only on \((h_R,h_G)\).  

    ---

    ## 8. Summary
    - Market Controller: only split/merge, dumb and neutral.  
    - SLP: applies LMSR maths, provides deterministic liquidity.  
    - Funding \(F\) defines liquidity parameter \(b\).  
    - Binary market: Red + Green with complementary pricing.  
