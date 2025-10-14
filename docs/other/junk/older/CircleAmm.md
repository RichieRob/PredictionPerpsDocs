GROK

# Elliptical and Circle Automated Market Maker (AMM) Models

This document provides a high-level overview of the elliptical model AMM and its symmetric special case, the circle AMM. The models are described from a "holdings" perspective, where the AMM's state is defined by the current token reserves (holdings) \( h_R \) and \( h_G \) for two tokens (e.g., Red and Green). At initialization, holdings are assumed equal: \( h_R = F \), \( h_G = F \), where \( F \) is the initial funding amount. Fees are ignored in this model for simplicity.

The elliptical AMM is based on the work of Wang, as detailed in the referenced paper. The circle AMM is a symmetric simplification of the elliptical model, ensuring equal treatment of both tokens.

## Elliptical Model AMM

### Overview

The elliptical AMM uses a cost function or invariant shaped like an ellipse in the reserve space. This generalizes constant-product AMMs (like Uniswap) by allowing tilted or squeezed level sets while maintaining convexity on the feasible branch (typically the lower-left arc in the first quadrant). It provides efficient computation (additions, multiplications, and one square root for block trades) and supports asymmetric token treatment if needed.

### State and Holdings

- **Holdings (Reserves)**: Let \( h_R = x \) and \( h_G = y \) represent the current holdings of the two tokens.
- **Initialization**: At genesis, \( h_R = F \), \( h_G = F \), ensuring symmetry unless parameters introduce bias.

### Invariant / Cost Function

The general constant-ellipse invariant proposed by Wang is:

\[
C(h_R, h_G) = (h_R - a)^2 + (h_G - a)^2 + b \cdot h_R \cdot h_G,
\]

where:

- \( a > 0 \) is a center parameter (related to the ellipse's offset),
- \( b \) is a tilting/squeezing parameter (controls asymmetry; \( b \neq 0 \) tilts the ellipse).

Trades occur along the level sets of \( C \) (constant \( C = k \)), specifically the convex lower-left branch in the first quadrant. The invariant ensures that after a trade, the new holdings satisfy \( C(h_R', h_G') = C(h_R, h_G) \).

For \( n=2 \) tokens, this is convex and admits efficient arithmetic for swaps.

### Exchange Rates and Trades

- **Instantaneous Rate**: Derived from the tangent slope of the ellipse.
- **Block Trades**: Solve the quadratic equation from the invariant for the output amount, involving one square root.

### Reference

This model is from Wang's paper: "Automated Market Makers Designs for Decentralized Finance" (arXiv:2009.01676v3). See Sections 2–4 and 6 for the ellipse cost/invariant, price derivatives, and generalizations.

## Circle AMM (Symmetric Case)

### Overview

The circle AMM is a special case of the elliptical model where \( b = 0 \), reducing the invariant to a perfect circle. This ensures complete symmetry between the tokens (\( h_R \) and \( h_G \) are treated identically, with no tilting). It is "normal" and intuitive when no specific shape is preferred, and reserves start equal.

### State and Holdings

- **Holdings (Reserves)**: \( h_R = x \), \( h_G = y \).
- **Initialization**: \( h_R = F \), \( h_G = F \).
- **Parameters**: Center \( c > 0 \), fixed radius \( r > 0 \). These can be pinned to match initial holdings (e.g., \( c = F \), \( r = F\sqrt{2} \) so the initial point lies on the circle).

### Geometry and Invariant

The AMM constrains holdings to the lower-left arc of the circle in the first quadrant. Two equivalent implementations:

#### Approach I: Scaled Circle

Use a scaling factor \( \mu > 0 \) to fit holdings to the circle:

\[
(\mu h_R - c)^2 + (\mu h_G - c)^2 = r^2,
\]

with \( \mu h_R < c \), \( \mu h_G < c \) (ensuring the lower-left arc).

#### Approach II: Cost as Circle (No Scaling)

Define the cost function directly:

\[
C(h_R, h_G) = (h_R - c)^2 + (h_G - c)^2 = k,
\]

where \( k = r^2 \). Trades move along constant-\( C \) level sets (convex branch).

At initialization (\( h_R = F \), \( h_G = F \)):

\[
(F - c)^2 + (F - c)^2 = r^2 \implies 2(F - c)^2 = r^2.
\]

### Instantaneous Exchange Rate

For the circle \( u^2 + v^2 = r^2 \) with \( u = \mu h_R - c \), \( v = \mu h_G - c \) (Approach I):

\[
\frac{d(\mu h_G)}{d(\mu h_R)} = -\frac{c - \mu h_R}{c - \mu h_G} \implies \text{Rate (} h_G \text{ per } h_R\text{)} = \frac{c - \mu h_R}{c - \mu h_G}.
\]

For infinitesimal input \( dh_R > 0 \), output \( dh_G = dh_R \cdot \frac{c - \mu h_R}{c - \mu h_G} \).

In Approach II (no \( \mu \)):

\[
\text{Rate} = \frac{c - h_R}{c - h_G}.
\]

As one holding approaches 0, the rate diverges, creating a natural barrier against depletion.

### Block-Trade Formulas

For a block trade input \( \Delta h_R > 0 \) (buy \( h_G \), sell \( h_R \); no fees):

- New holdings: \( h_R' = h_R + \Delta h_R \), \( h_G' = h_G - \Delta h_G \).
- Solve the invariant for \( \Delta h_G \) (Approach I):

\[
\Delta h_G = h_G - \frac{1}{\mu} \left[ c - \sqrt{r^2 - (\mu (h_R + \Delta h_R) - c)^2} \right].
\]

Pick the lower-left branch (minus sign in square root).

For Approach II (no \( \mu \)):

\[
\Delta h_G = h_G - \left[ c - \sqrt{r^2 - (h_R + \Delta h_R - c)^2} \right].
\]

Symmetry: Swap roles for the opposite direction.

### Relation to Elliptical Model

Setting \( b = 0 \) in the elliptical invariant reduces to the circle, ensuring symmetry (\( \lambda_0 = \lambda_1 = 1 \)).

## Implementation Considerations

### From Holdings Perspective

The AMM operates directly on holdings \( h_R, h_G \):

- **State**: Store \( h_R, h_G, c, r \) (or \( \mu \) if using Approach I).
- **Initialization**: Set \( h_R = F \), \( h_G = F \). Choose \( c = F \), \( r = F\sqrt{2} \) to place the initial point on the circle.
- **Quotes**: For input \( \Delta h_R \), compute \( \Delta h_G \) using the block-trade formula (one square root; gas-efficient).
- **Updates**: After trade, update holdings: \( h_R += \Delta h_R \), \( h_G -= \Delta h_G \).
- **Barrier**: Rate explosion prevents holdings from reaching 0 with finite input.
- **Symmetry**: Circle ensures identical treatment of tokens.

### Solidity Snippet (Approach II, No Fees)

For reference, a simplified Solidity implementation for quoting (using fixed-point math and Babylonian square root):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CircleAMM {
    uint256 public hR; // Red holdings
    uint256 public hG; // Green holdings
    uint256 public c; // Center
    uint256 public rSquared; // r^2
    uint256 public constant PRECISION = 1e18;

    constructor(uint256 F) {
        hR = F;
        hG = F;
        c = F;
        rSquared = 2 * F * F; // r^2 = 2 F^2
    }

    // Babylonian square root
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    // Quote output DeltaG for input DeltaR (buy G, sell R)
    function quoteG(uint256 deltaR) public view returns (uint256 deltaG) {
        uint256 newHR = hR + deltaR;
        uint256 term = rSquared - (newHR - c) * (newHR - c);
        require(term >= 0, "Trade exceeds circle");
        uint256 sqrtTerm = sqrt(term);
        deltaG = hG - (c - sqrtTerm);
        require(deltaG <= hG, "Insufficient holdings");
    }

    // Execute trade (simplified)
    function swapG(uint256 deltaR) external returns (uint256 deltaG) {
        deltaG = quoteG(deltaR);
        hR += deltaR;
        hG -= deltaG;
        // Token transfers omitted
    }
}
```

This uses holdings directly and assumes integer values (scale with PRECISION for decimals).

## Citations

- Wang, 2020. "Automated Market Makers Designs for Decentralized Finance." arXiv:2009.01676v3. (General ellipse model.)
- Wang, 2021. "Implementation Notes on Constant Ellipse based AMMs." arXiv:2103.03699v1. (Circle implementation details.)