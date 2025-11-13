---
title: Market Pricing
description: How prices are computed from stored state variables in the LMSR market.
---

# Market Pricing

---

## 1 · Overview

Once the market is initialised, all prices are derived directly from the stored **R values**,  
the **reserve**, and the **denominator**.

\[
\text{denom} = S_{\text{tradables}} + R_{\text{reserve}}
\]

These determine the **Back**, **Lay**, and **Other** prices for every position.

---

## 2 · Back Price

### Whitepaper Maths

For each listed outcome \( i \):

\[
p_i = \frac{e^{q_i / b}}{\sum_j e^{q_j / b}} = \frac{R_i}{\text{denom}}
\]

where  

- \(R_i = e^{u_i / b}\) is the local cached exponential term,  
- \(\text{denom} = S_{\text{tradables}} + R_{\text{reserve}}\),  
- \(b\) is the liquidity depth parameter.

### Solidity Interface

```solidity
function getBackPriceWad(
    uint256 marketId,
    uint256 ledgerPositionId
)  view returns (uint256);
```

Returned as **1e18** fixed-point

---

## 3 · Lay Price 

### Whitepaper Maths

The **Lay** (Back all not-i) price is the complement of the Back price:

\[
p_{\text{lay}(i)} = 1 - p_i
\]

This represents the cost of buying the *rest of the market* (everything except \(i\)).

### Solidity Interface

```solidity
function getLayPriceWad(
    uint256 marketId,
    uint256 ledgerPositionId
)  view returns (uint256);
```

Returned as **1e18** fixed-point

---

## 4 · Back (“Other”) Price

### Whitepaper Maths

The **reserve price** represents the price of unlisted outcomes —  
the “Other” bucket that holds the remaining fraction.

\[
p_{\text{other}} = \frac{R_{\text{reserve}}}{\text{denom}}
\]

This ensures that all prices sum to 1:

\[
\sum_i p_i + p_{\text{other}} = 1
\]

### Solidity Interface

```solidity
function getReservePriceWad(
    uint256 marketId
)  view returns (uint256);
```

Returned as **1e18** fixed-point.

---

## 5 · Summary

| Price Type | Whitepaper Equation | Solidity Function | Scale |
|-------------|--------------------|-------------------|--------|
| **Back(i)** | \(p_i = R_i / \text{denom}\) | `getBackPriceWad` | 1e18 |
| **Lay(i)** | \(p_{\text{lay}(i)} = 1 - p_i\) | `getLayPriceWad` | 1e18 |
| **Back(Other)** | \(p_{\text{other}} = R_{\text{reserve}} / \text{denom}\) | `getReservePriceWad` | 1e18 |

---