---
comments: true
slug: lmsr-quotes  # Stable ID, e.g., for linking as /what-is-it/
title: LMSR Quotes  # Optional display title
---

---
title: Market Quoting — Closed-Form LMSR
description: How the LMSR AMM computes BACK and LAY quotes for buys and sells, and how this maps to the Solidity implementation.
---

# Market Quoting

This page explains **how our LMSR AMM computes quotes** for trades.

All quoting logic uses the **exact closed-form LMSR formulas** from the whitepaper.  

READ MORE ABOUT HOW THE MATHS WORKS IN THE WHITEPAPER

These are implemented inside `LMSRQuoteLib` and exposed via four external functions on `LMSRMarketMaker`.

## 0 Definition of Terms

- \(p \equiv p_i\) is the **BACK price** of outcome \(i\)  
- The **LAY** price is \(1 - p\)  
- \(t\) is **tokens traded**, \(m\) is **money charged / paid**  
- \(b\) is the LMSR **liquidity parameter**

---

## 1 · Quote how much USDC given tokens

Given a token trade size \(t\) and current BACK price \(p\), LMSR computes the **money charged or paid**.

### **Table 1 — Quote USDC given TOKENS**

| Action | BACK Formula | LAY Formula | Function |
|--------|------------------|---------------------|-------------------|
| **Buy** | \( m = b \ln(1 - p + p e^{t/b}) \) | \( m = b \ln(p + (1-p)e^{t/b}) \) | `quoteBuy` |
| **Sell** | \( m = b \ln(1 - p + p e^{-t/b}) \) | \( m = b \ln(p + (1-p)e^{-t/b}) \) | `quoteSell` |


---

## 2 · Inverse Formulas (Money → Tokens)

Given a target money amount \(m\), LMSR can invert the cost curve to compute the **token amount** \(t\).

### **Table 2 — Money → Tokens (Inverse LMSR)**

| Action | BACK Formula | LAY Formula | Function |
|--------|------------------|---------------------|-------------------|
| **Buy for USDC** | \( t = b \ln\!\left(1 + \frac{e^{m/b}-1}{p}\right) \) | \( t = b \ln\!\left(\frac{e^{m/b}-p}{1-p}\right) \) | `quoteBuyForUSDC` |
| **Sell for exact USDC out** | \( t = -b \ln\!\left(\frac{e^{m/b}-1+p}{p}\right) \) | \( t = -b \ln\!\left(\frac{e^{m/b}-p}{1-p}\right) \) | `quoteSellForUSDC` |

---

## 4 · External Solidity Interfaces

The following view functions are the **public quoting API**:

---

### 4.1 quoteBuy

```solidity
function quoteBuy(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 t
) public view returns (uint256 m) {
    return LMSRQuoteLib.quoteBuyInternal(
        this,
        marketId,
        ledgerPositionId,
        isBack,
        t
    );
}
```

- `t` is the exact token size (1e6).  
- `m` is the **USDC cost** (1e6).  
- `isBack = true` → BACK buy; `false` → LAY buy.

---

### 4.2 quoteSell

```solidity
function quoteSell(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 t
) public view returns (uint256 m) {
    return LMSRQuoteLib.quoteSellInternal(
        this,
        marketId,
        ledgerPositionId,
        isBack,
        t
    );
}
```

- `t` is the exact token size (1e6).  
- `m` is the **USDC proceeds** (1e6).  
- `isBack = true` → selling BACK; `false` → selling LAY.

---

### 4.3 quoteBuyForUSDC

```solidity
function quoteBuyForUSDC(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 mFinal
) public view returns (uint256 tOut) {
    return LMSRQuoteLib.quoteBuyForUSDCInternal(
        this,
        marketId,
        ledgerPositionId,
        isBack,
        mFinal
    );
}
```

- `mFinal` is **USDC in** (1e6).  
- `tOut` is **tokens out** (1e6).  
- `isBack = true` → BACK buy for USDC; `false` → LAY buy for USDC.

---

### 4.4 quoteSellForUSDC

For **sells**, we sometimes want the inverse direction:

> *“How many tokens do I have to sell to receive exactly $m$ USDC out?”*

```solidity
function quoteSellForUSDC(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 mFinal
) public view returns (uint256 tIn) {
    return LMSRQuoteLib.quoteSellForUSDCInternal(
        this,
        marketId,
        ledgerPositionId,
        isBack,
        mFinal
    );
}
```

- `mFinal` is the **target USDC out** (1e6).  
- `tIn` is the **number of tokens** (1e6).  
- `isBack = true` → selling BACK tokens for exact USDC; `false` → selling LAY.

---
