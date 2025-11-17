---
comments: true
slug: lmsr-initialisation-storage  # Stable ID, e.g., for linking as /what-is-it/
title: LMSR Intialisation Storage  # Optional display title
---

# Market Initialisation — Stored State

---

## 1 · What gets stored (per market)

| Variable | Purpose | Whitepaper Equivalent | Scale |
|-----------|----------|-----------------|--------|
| `b[marketId]` | Liquidity depth, defines market responsiveness | \(b\) | 1e18 |
| `G[marketId]` | Global factor applied to all outcomes | \(G = e^{U_{all}/b}\) | 1e18 |
| `R[marketId][slot]` | Local mass for each listed outcome | \(R_i = e^{u_i/b}\) | 1e18 |
| `S[marketId]` | Sum positions and reserve | \(\sum_i R_i\)| 1e18 |
| `R_reserve[marketId]` | Reserve mass (“Other”) for future expansion | \(R_{reserve} = e^{u_{reserve}/b}\) | 1e18 |

---

## 2 · Initialising Market Inputs

When a market is initialised, the following inputs are defined:

- **Initial weights for each traded position** — from which R values and thus prices are derived.  
- **Liability (USDC)** — used to calculate the liquidity depth `b`.  
- **Reserve weight** — an amount reserved for untraded positions.  

These are passed into `LMSRInitLib.initMarketInternal` during market creation.  
The function checks that positions exist in the ledger, normalises weights, and stores them.

---

## 3 · Example Market 

Below shows the stored state after initialisation for the **Fruit Market** example.

**Inputs used:**  

- **Initial weights:** (ledgerPositionId, weighting) → {(0, 4), (1, 1), (2, 3)}  
- **Liability (USDC):** 10 000 × 10⁶  
- **Reserve weight:** 2

```solidity
initMarket(
    0,
    { positionId: "0",    weight: "4" },
    { positionId: "1",   weight: "1" },
    { positionId: "2", weight: "3" },
    10000000000,
    2,
    true
);
```

LINK BACK TO MARKET INITIALISATION EXAMPLE

---

## Calculations needed for stored values on initialisation

### Calculation for b

#### Whitepaper Maths

The liquidity depth \(b\) controls how responsive prices are to trades.  
It is defined as:

\[
b = \frac{\text{liability}_{USDC} \times 10^{18}}{\ln(n_{\text{effective}})}
\]

where \(n_{\text{effective}}\) includes the reserve if `isExpanding = true`.  

For this example:

\[
b = \frac{10{,}000 \times 10^{18}}{\ln(4)} \approx 7.21 \times 10^{21}
\]

A larger \(b\) → smoother prices; a smaller \(b\) → sharper price movements.

#### Solidity Implementation

```solidity
function calculateB(
    uint256 liabilityUSDC, 
    uint256 _numInitial
    ) internal pure returns (int256 _b)
```
---

### Calculation for normalising weights (R values)

#### Why Normalise

To ensure all initial weights sum to 1e18. This is so there is scope for price movements within the constraint of solidity integer maths.

#### Normalisation Maths

Given initial (unnormalised) weights \( r_i \) and reserve \( r_{\text{reserve}} \),  
the total before scaling is:

\[
T = r_{\text{reserve}} + \sum_i r_i
\]

Each weight is then scaled proportionally so that the total equals \( 10^{18} \):

\[
R_i = \frac{r_i \times 10^{18}}{T}
\]

and

\[
R_{\text{reserve}} = \frac{r_{\text{reserve}} \times 10^{18}}{T}
\]

The post-normalisation total satisfies:

\[
\sum_i R_i + R_{\text{reserve}} = 10^{18}
\]

#### Solidity Implementation

Each \(R_i\) and the reserve are scaled proportionally.

```solidity
function _normalizeToWadTotal(
    InitialPosition[] memory positions,
    int256 reserve0,
    bool isExpanding
    ) internal pure 
```

---

### Stored Values After Initialisation

| Variable | Stored Values (Fruit Market) | Notes |
|-----------|------------------------------|--------|
| `b` | 7.213 × 10¹⁸ | Calculated from liability = 10 000 USDC and effective n = 4 |
| `G` | 1 × 10¹⁸ | Neutral global factor |
| `R[0]` | `[0.4e18, 0.1e18, 0.3e18]` | Stored R values normalised to 1e18 |
| `S` | 1e18 | Sum of R including R_reserve|
| `R_reserve` | 0.2e18 | Reserve (“Other”) component |

---
