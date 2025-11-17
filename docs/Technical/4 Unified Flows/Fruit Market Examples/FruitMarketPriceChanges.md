---
comments: true
slug: fruit-market-price-changes
title: Fruit Market Price Changes
---


# Fruit Market — Worked Trading Walkthrough (Single Trade Example)

This page walks through **one complete LMSR trade** on the Fruit market, showing:

- How cost is calculated  
- How many tokens are minted  
- How \(R_i\), \(S\), and \(G\) update  
- How prices shift  

We follow the LMSR decomposition:

\[
Z = G \cdot S,\quad S = \sum_i R_i,\quad p_i = \frac{R_i}{S}
\]

The trade examined is:

> **Buy 100 USDC worth of BACK Apple**

We use the same liquidity depth \(b\) as in the **Market Initialisation — Stored State** example:

- Effective outcomes (including reserve): \(n_{\text{effective}} = 4\)  
- Liability: \(10{,}000\) USDC  

\[
b \approx \frac{10{,}000}{\ln 4} \approx 7{,}213
\]

---

## 1 · Starting Point — Initialised Fruit Market

We assume LMSR with:

- \(b \approx 7{,}213\)  
- Global factor \(G = 1.0\)  
- Local weighting vector \(R_i\) chosen to match target starting prices  

**Initial LMSR state**

| Outcome               | \(R_i\) × 10¹⁸ | Price \(p_i = R_i/S\) |
|-----------------------|----------------:|-----------------------:|
| Apple (APL)           | 0.400000        | 0.4000                |
| Banana (BAN)          | 0.100000        | 0.1000                |
| Cucumber (CUC)        | 0.300000        | 0.3000                |
| Dragon Fruit (DRF)    | 0.100000        | 0.1000                |
| Reserve (OTHER)       | 0.100000        | 0.1000                |
| **Total PRICE**       |                 | **1.0000**            |
| **SUM OF R VALUES (S)** | **1.000000**   |                       |
|                       |                 |                       |
| *Global Factor (G)*   | *1.000000*      |                       |

---

## 2 · Trade 1 — Buy BACK Apple with 100 USDC

This uses:

- **Function:** `quoteBuyForUSDCInternal`  
- **Direction:** BACK side of Apple  
- **Input:** exact **100 USDC**  
- **Output:** tokens minted (`t`)

---

## 2.1 · Quote Calculation (Money → Tokens)

Formula for **BACK buy for USDC**:

\[
t = b \ln\!\left(1 + \frac{e^{m/b}-1}{p}\right)
\]



Inputs:

- BACK price of Apple: \(p = 0.40\)  
- Money: \(m = 100\)  
- Liquidity Constant: \(b \approx 7{,}213\)

\[
t = 7{,}213 \ln\!\left(1 + \frac{e^{100/7{,}213}-1}{0.40}\right)
\]

**Tokens minted:**

\[
t \approx 247.45\ \text{Back Apple}
\]

**Cost:** fixed at **100 USDC** (this is the input to `quoteBuyForUSDC`).

---

## 2.2 · LMSR State Update (χ-factors)

For a **BACK buy of Apple**, we update the LMSR state via:

\[
G' = \chi G \cdot G,\quad R_{\text{Apple}}' = \chi {R_\text{Apple}} \cdot R_{\text{Apple}},\quad R_i' = R_i\ (i \neq \text{Apple})
\]

Buying BACK tokens sets:

\[
\chi G = 1  
\]

\[
\chi {R_\text{Apple}} = e^{t/b}
\]

substituting in \(\chi {R_\text{Apple}}\):

\[
\chi {R_\text{Apple}} = e^{247.45/7{,}213} = 1.0349010
\]

So:

\[
R_{\text{Apple}}' = \chi {R_\text{Apple}} \cdot R_{\text{Apple}}
= 1.0349010 \times 0.400000
\approx 0.4139604
\]

Other positions unchanged



We update S using the LMSR rule:

\[
S' = S - R_k + R_k'
\]

For this trade:

- \(S = 1.000000\)
- \(R_k = R_{\text{Apple}} = 0.400000\)
- \(R_k' = 0.4139604\)

So:

\[
S' = 1.000000 - 0.400000 + 0.4139604 = 1.0139604
\]

Global factor:

\[
G' = \chi G \cdot G \cdot = 1 \cdot 1 = 1
\]

---

## 2.3 · State After Trade

New prices:

\[
p_i' = \frac{R_i'}{S'}
\]

- Apple:

\[
p_{\text{Apple}}' = \frac{0.4139604}{1.0139604} \approx 0.4083
\]

- Banana / Dragon / Reserve:

\[
p_{\text{Banana}}' = p_{\text{Dragon}}' = p_{\text{Reserve}}'
= \frac{0.100000}{1.0139604} \approx 0.0986
\]

- Cucumber:

\[
p_{\text{Cucumber}}' = \frac{0.300000}{1.0139604} \approx 0.2959
\]

**Updated LMSR state**

| Outcome               | \(R_i'\) × 10¹⁸ | Price \(p_i' = R_i'/S'\) |
|-----------------------|-----------------:|--------------------------:|
| Apple (APL)           | 0.413960         | 0.4083                   |
| Banana (BAN)          | 0.100000         | 0.0986                   |
| Cucumber (CUC)        | 0.300000         | 0.2959                   |
| Dragon Fruit (DRF)    | 0.100000         | 0.0986                   |
| Reserve (OTHER)       | 0.100000         | 0.0986                   |
| **Total PRICE**       |                  | **1.0000**               |
| **SUM OF R VALUES (S')** | **1.013960**   |                          |
|                       |                  |                          |
| *Global Factor (G')*  | *1.000000*       |                          |

---

## ✔️ Summary of Effects

- Apple’s \(R\) increased by **≈ 3.49%**  
- \(S\) increased from **1.000000 → ≈ 1.013960**  
- Apple’s price shifted **0.4000 → ≈ 0.4083**  
- Other prices fell slightly because \(S\) grew while their \(R_i\) stayed constant  
- \(G\) stayed at **1.0**, so all movement was captured in the local \(R_i\) and \(S\)

--8<-- "link-refs.md"
