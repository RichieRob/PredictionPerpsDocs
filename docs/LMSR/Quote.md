
---
title: Quote Flow — Exact USDC In (Partition Function View)
description: Read‑only quotes using the LMSR partition ratio \(m = b \ln(Z_\text{new}/Z_\text{old})\), with \(Z = G \cdot \text{denom}\).
---

# Quote Flow — Exact USDC In (Partition Function View)

> **What is a quote?**  
> A quote is a **read‑only** simulation of a trade. It answers “how many tokens would I get for this USDC (after fee removed)?” without changing on‑chain state.

We support two quote modes in code:
- **Exact USDC‑in → tokens‑out** *(this page)*
- **Exact tokens‑out → USDC cost** *(covered separately)*

---

## 1 · Maths Overview

The LMSR cost of changing state is

\[
m \;=\; b \cdot \ln\!\left(\frac{Z_\text{new}}{Z_\text{old}}\right),
\qquad Z \;=\; G \cdot \text{S},
\qquad \text{S} \;=\; denom \,
\]




---

## 2 · What the contract does (Exact USDC‑in)

1) **Strip fee** from the user’s USDC input \(m_{\text{final}}\) to get net spend \(m\).  
2) **Read price** \(p_i = R_i / \text{denom}\) for the requested position \(i\).  
3) **Solve tokens out** \(t\) from the closed form implied by \(m = b \ln(Z_\text{new}/Z_\text{old})\).  
4) **Return \(t\)** — no state change.

### Solidity (interfaces)

```solidity
// Quote with exact USDC-in (fee stripped internally)
function quoteBuyForUSDC(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 usdcIn
) external view returns (uint256 tOut);

// Optional: tokens-out -> USDC-in (symmetric path, shown elsewhere)
function quoteBuyInternal(
    uint256 marketId,
    uint256 ledgerPositionId,
    bool isBack,
    uint256 t
) external view returns (uint256 mNoFee);
```

---

## 3 · Actions — USDC‑in → tokens‑out

Let \(p = p_i = R_i/\text{denom}\) read from state.

### A) Buy **Back(i)**
Intuition: increase weight of \(i\).  
Tokens‑out (closed form used by the contract):
\[
t \;=\; b \cdot \ln\!\Big( 1 \;+\; \frac{e^{m/b} - 1}{p} \Big) \,.
\]

### B) Buy **Lay(not‑i)**
Intuition: increase the “everything except \(i\)” side.  
\[
t \;=\; b \cdot \ln\!\Big( \frac{e^{m/b} - p}{1 - p} \Big) \qquad (\text{domain: } e^{m/b} > p)\,.
\]

### C) Sell **Back(i)** (proceeds for tokens \(t\))
Symmetric read (shown here for completeness):
\[
m \;=\; b \cdot \ln\!\big( 1 - p + p\,e^{-t/b} \big) \,.
\]

### D) Sell **Lay(not‑i)** (proceeds for tokens \(t\))
\[
m \;=\; b \cdot \ln\!\big( p + (1 - p)\,e^{-t/b} \big) \,.
\]

> Note: For this page’s **USDC‑in** focus, the contract primarily uses A/B inverse forms to compute \(t\) from \(m\). The sell equations are included for reference and symmetry.

---

## 4 · Fee handling (quick note)

Quotes that take **USDC‑in** first remove protocol fee to get the net spend \(m\) used in formulas above:

\[
m \;=\; m_{\text{final}} \cdot \frac{10{,}000}{10{,}000 + \text{FEE\_BPS}} \,.
\]

This mirrors the logic in `LMSRQuoteLib.quoteBuyForUSDCInternal`.

---

## 5 · Minimal example (pseudocode)

```solidity
(uint256 pWad) = getBackPriceWad(marketId, ledgerPositionId); // 1e18
uint256 mNet   = stripFee(usdcIn);                            // 1e6
int256  tOut   = closedFormBackOrLay(isBack, pWad, mNet, b);  // uses exp/ln on sd59x18
return uint256(tOut);
```

---

## 6 · Summary (USDC‑in → tokens‑out)

| Action | Uses price | Tokens‑out (from \(m = b \ln(Z_\text{new}/Z_\text{old})\)) |
|---|---|---|
| **Buy Back(i)** | \(p = R_i/\text{denom}\) | \(t = b \ln\!\Big( 1 + \frac{e^{m/b} - 1}{p} \Big)\) |
| **Buy Lay(not‑i)** | \(p = R_i/\text{denom}\) | \(t = b \ln\!\Big( \frac{e^{m/b} - p}{1 - p} \Big)\) |

> Everything hinges on the partition ratio \(Z_\text{new}/Z_\text{old}\); with \(Z = G \cdot \text{denom}\), the closed forms above fall out directly without recomputing sums over outcomes.
