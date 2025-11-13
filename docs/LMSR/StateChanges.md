---
title: State Change — O(1) Updates (with χ factors)
description: How an LMSR market updates its cached state (G, R, S, denom, Z) for each action using explicit multiplicative factors χ_G and χ_{R_k}. Also clarifies the meaning and sign of t.
---

# State Changes


---

## 0 · What do we need to track?

We want to track values to compute our cost function C so we know how much a trade costs.

Addtionally we want to know the marginal prices of positions.

### Cost function ###

\[
C(\mathbf{q}) = b \ln Z(\mathbf{q})
\]

cost of a trade

\[
C(\mathbf{q'}) - C(\mathbf{q})
\]


### Decomposition ###

\[
Z(\mathbf{q}) \;=\; G \cdot \ S
\]

where S is a sum of local weightings

\[
\qquad
    S \;\equiv\; \sum R_i + R_{\text{reserve}}
\]

and G is a global shift



### Price Function ###


\[
p_i \;=\; \frac{R_i}{\ S},
\qquad
p_{\text{other}} \;=\; \frac{R_{\text{reserve}}}{\ S},
\qquad
p_{\text{lay}(i)} \;=\; 1 - p_i.
\]

### What changes each trade and what remains constant ###


- \(b\) — liquidity depth (constant per market)

- \(G\) — global multiplier

- \(R_i\) — local multipliers for listed positions

- \(S\) — running sum \(\sum R_i + R_{\text{reserve}}\) 

- \(R_{\text{reserve}}\) — weighting for non listed positions (constant unless split)


### State Changes for each Trade that need to be tracked

- \(G\)

- \(R_i\)

- \(S\) 


## 1 · The General Update Rule 

Our state changes as seen in the LMSR Whitepaper depend on us updating the above values 

Where

\[
\begin{aligned}
G'   &= G \cdot \chi G, \\[2pt]
R_k' &= R_k \cdot \chi {R_k}, \\[2pt]
S'   &= S - R_k + R_k', \\[2pt]
\end{aligned}
\]

Thus state changes depend upon calculating the two multiplicative factors  $\chi G$ and $\chi {R_k}$.


## Calculating the multiplicative factors

From the whitepaper

\[
\chi G \;\equiv\; e^{\Delta U_{\text{rest}}/b},
\qquad
\chi {R_k} \;\equiv\; e^{(\Delta U_k - \Delta U_{\text{rest}})/b}.
\]

where

- \( \Delta U_k \) (local offset change \(k\))

- \( \Delta U_{\text{rest}} \) (change for eveything else)



For a trade size of t tokens

| Action              | \( \Delta U_{\text{rest}} \) | \( \Delta U_k \) | Intuition |
|---------------------|------------------------------:|-----------------:|-----------|
| **Buy · Back(k)**   | 0                             | \(+t\)           | Make slot \(k\) heavier vs rest |
| **Sell · Back(k)**  | 0                             | \(-t\)           | Make slot \(k\) lighter vs rest |
| **Buy · Lay(k)**    | \(+t\)                        | 0                | Push **rest of market** up |
| **Sell · Lay(k)**   | \(-t\)                        | 0                | Pull **rest of market** down |

This makes the χ factors for each case:

- **Buy Back(k)**:  
  \( \chi G = 1,\quad \chi {R_k} = e^{+t/b}. \)
- **Sell Back(k)**:  
  \( \chi G = 1,\quad \chi {R_k} = e^{-t/b}. \)
- **Buy Lay(k)**:  
  \( \chi G = e^{+t/b},\quad \chi {R_k} = e^{-t/b}. \)
- **Sell Lay(k)**:  
  \( \chi G = e^{-t/b},\quad \chi {R_k} = e^{+t/b}. \)

---

## Where is this in the code

The state χ factors are calculated in applyUpdateInternl which is found in the LMSRUpdateLib.
This function calculates chi G chiRk and updates G Rk and S

```solidity

function applyUpdateInternal(
        LMSRMarketMaker self,
        uint256 marketId,
        uint256 slot,
        bool isBack,
        bool isBuy,
        uint256 t
    ) internal

```

**[LMSRUpdateLib.sol](https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRUpdateLib.sol)**

