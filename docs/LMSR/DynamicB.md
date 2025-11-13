---
title: Dynamic Reparameterisation of `b` When Splitting Off Reserve
description: How to preserve max exposure, preserve prices, and keep LMSR fully consistent when creating a new outcome by splitting the reserve, using an O(1) reparameterisation of b and G.
---

# Dynamic Reparameterisation of `b` When Splitting Off Reserve  
**(O(1) LMSR state transformation for adding new outcomes)**

This note explains how to **change the LMSR liquidity parameter `b`** *at runtime* when the market adds a new explicit outcome by **splitting probability mass from the reserve**, **without touching any listed outcome Rᵢ**, and **without breaking O(1) update logic**.

This enables the protocol to:

- preserve **max exposure**  
- preserve **all existing prices**  
- preserve **current PnL/cost surface**  
- add a new position **mid‑market**  
- avoid recomputing every Rᵢ  

---

## 1 · Why we need to adjust `b`

The LMSR worst‑case loss is:

\[
\text{MaxLoss} = b \cdot \ln(n)
\]

If the market originally had `n_old` outcomes and you selected `b` to cap exposure at **10,000 USDC**, then:

\[
\text{MaxLoss} = 10{,}000
\]

But if you **add a new outcome** by splitting the reserve:

- new number of outcomes = `n_new = n_old + 1`
- LMSR exposure **increases** if `b` is not adjusted.

To keep exposure constant:

\[
b' = b \cdot \frac{\ln(n_{\text{old}})}{\ln(n_{\text{new}})}
\]

This ensures:

\[
b \ln n_{\text{old}} = b' \ln n_{\text{new}}
\]

so maximum loss stays fixed.

---

## 2 · Invariants we must preserve at the moment of the split

Since we only split the **reserve**, at the split moment:

- **All listed outcomes keep the same Rᵢ**
- **Prices must remain unchanged**

\[
p_i = \frac{R_i}{S}
\]

- **Total cost C must remain unchanged**

\[
C = b \ln Z = b \ln(G S)
\]

- **S must remain unchanged**
- **Only the reserve is replaced by:**
  - smaller reserve  
  - a new explicit outcome  
- **No PnL discontinuities**

We change only:

- `b → b'`
- `G → G'`
- reserve → (reserve', R_new)

---

## 3 · Splitting the reserve into (reserve', new)

Let:

- `R_reserve` be the current hidden reserve weight  
- `α ∈ (0,1)` be how much mass we allocate to the new outcome

We set:

### New outcome:
\[
R_{\text{new}} = α \cdot R_{\text{reserve}}
\]

### Updated reserve:
\[
R_{\text{reserve}}' = (1-α) \cdot R_{\text{reserve}}
\]

Then:

\[
R_{\text{reserve}}' + R_{\text{new}}
= R_{\text{reserve}}
\]

So:

### ✔ S stays the same  
### ✔ All existing Rᵢ stay the same  
### ✔ Prices stay the same  

Only one R-value is split into two.

---

## 4 · O(1) reparameterisation of `b` and `G`

We want:

\[
b \ln(G S) = b' \ln(G' S)
\]

Let:

\[
Z = G S
\]

Solve:

\[
G' S = Z' = Z^{b/b'}
\]

Thus:

\[
G' = \frac{Z'}{S}
     = \frac{(G S)^{b/b'}}{S}
\]

This requires **no iteration over outcomes**.

---

## 5 · Complete O(1) algorithm for adding a new outcome

**Given:**  
`b`, `G`, `S`, `R_reserve`, `n_old`, split parameter `α`.

1. **Compute new b**
   \[
   b' = b \frac{\ln n_{old}}{\ln n_{new}}
   \]

2. **Split the reserve**
   ```
   R_new       = α * R_reserve
   R_reserve'  = (1 - α) * R_reserve
   ```
   (S remains unchanged)

3. **Recompute G (O(1))**
   ```
   Z      = G * S
   ratio  = b / bPrime
   Zprime = Z ** ratio              // exp( ratio * ln(Z) )
   Gprime = Zprime / S
   ```

4. **Commit new state**
   ```
   b = bPrime
   G = Gprime
   ```

All other Rᵢ remain unchanged.

---

## 6 · Solidity Sketch

```solidity
int256 bPrime = bOld * ln(n_old) / ln(n_new);

// Split reserve
R_new        = alpha * R_reserve;
R_reserveNew = (ONE - alpha) * R_reserve;

int256 Z = G * S;
int256 ratio = bOld / bPrime;

int256 Zprime = exp( ln(Z) * ratio );
int256 Gprime = Zprime / S;

b = bPrime;
G = Gprime;
```

---

## 7 · Summary Table

| Component | Changed? | How? |
|----------|----------|------|
| b | **Yes** | b′ = b ln(n_old) / ln(n_new) |
| G | **Yes** | G' = (G·S)^(b/b′) / S |
| R_reserve | **Yes** | R_reserve' = (1−α) R_reserve |
| R_new | **Yes** | R_new = α R_reserve |
| Other Rᵢ | No | unchanged |
| S | No | unchanged |
| Prices | No | unchanged |
| Max exposure | **No** | preserved |

