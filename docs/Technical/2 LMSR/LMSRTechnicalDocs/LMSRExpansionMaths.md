---
comments: true
slug: lmsr-expansion-maths  # Stable ID, e.g., for linking as /what-is-it/
title: LMSR Expansion Maths  # Optional display title
---


---
title: Splitting Positions in the LMSR
description: How PredictionPerps handles adding new positions in an LMSR market while preserving prices and exposure.
---
# Splitting Positions in the LMSR

---


## 1 · Philosophy

### 1.1 · Modifying the Liquidity Factor

When we **split a position** from the *reserve bucket*, the number of effective positions increases by one:

\[
n'_{\text{effective}} = n_{\text{effective}} + 1
\]

We require that **maximum liability remains constant**:

\[
L'_{\max} = L_{\max}
\]

During market initialization, the liquidity factor \( b \) was computed as:

\[
b = \frac{L_{\max}}{\ln(n_{\text{effective}})}
\]

After increasing the number of outcomes, we must recompute:

\[
b' = \frac{L_{\max}}{\ln(n'_{\text{effective}})}
\]

---

### 1.2 · Maintaining Prices of Existing Positions

Initial prices are defined by:

\[
p_i = \frac{R_i}{S}
\]

After the split, we want **all existing non-reserve prices unchanged**:

\[
p'_i = p_i
\]

The reserve bucket loses a fraction \( \alpha \):

\[
p'_{\text{reserve}} = p_{\text{reserve}} - \alpha\, p_{\text{reserve}}
\]

And the new position inherits the removed mass:

\[
p_{\text{new}} = \alpha\, p_{\text{reserve}}
\]

To achieve this cleanly, we define the following transformations on the LMSR local weights:

\[
R'_i = R_i
\]

\[
S' = S
\]

\[
R'_{\text{reserve}} = R_{\text{reserve}} - \alpha \cdot R_{\text{reserve}}
\]

\[
R_{\text{new}} = \alpha \cdot R_{\text{reserve}}
\]

---

## 2 · How These Changes Affect Stored LMSR Values

We now know exactly how:

- \( R_i \) (existing positions)
- \( R_{\text{reserve}} \)
- \( R_{\text{new}} \)
- \( S \)

transform.

What remains is the **global multiplier** \( G \).

Recall:

\[
Z = G S
\]

and the LMSR cost function:

\[
C = b \ln Z
\]

To preserve **total cost**:

\[
C' = C
\]

Thus:

\[
b'\ln Z' = b \ln Z
\]

Rearranging:

\[
\frac{b}{b'} = \frac{\ln Z'}{\ln Z}
\]

Using log rules:

\[
\frac{b}{b'} = \log_Z(Z')
\]

Taking anti-logs:

\[
Z' = Z^{\,b/b'}
\]

Since \( S \) is unchanged:

\[
Z' = G' S
\]

Therefore:

\[
G' = \frac{Z'}{S}
\]

Substitute the earlier expression:

\[
G' = \frac{Z^{\,b/b'}}{S}
\]

With \( Z = G S \):

\[
G' = \frac{(GS)^{\,b/b'}}{S}
\]

---

# Final Expressions

\[
\boxed{
n'_{\text{effective}} = n_{\text{effective}} + 1
}
\]

\[
\boxed{
b' = \frac{L_{\max}}{\ln(n'_{\text{effective}})}
}
\]

\[
\boxed{
R'_i = R_i,\quad
R'_{\text{reserve}} = R_{\text{reserve}} - \alpha R_{\text{reserve}},\quad
R_{\text{new}} = \alpha R_{\text{reserve}}
}
\]

\[
\boxed{
G' = \frac{(GS)^{\,b/b'}}{S}
}
\]

---

--8<-- "link-refs.md"
