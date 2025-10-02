# Fixed Product Market Maker (FPMM) for Prediction Markets


## Overview


This Fixed Product Market Maker (FPMM) prices Back and Lay tokens for prediction market outcomes using an unweighted constant-product invariant, forked from Balancer’s weighted pool math. It queries outcome reserves ($R_k = H_k = v + \text{tilt}[k]$) and collateral ($R_v = \min[H_k]$) from a ledger with a single market maker, maintaining $S = \sum_j 1/R_j$ and $\alpha_{\text{epoch}}$ for O(1) pricing and updates. The AMM requests or deposits tokens via the ledger without modifying $v$ or $\text{tilt}[k]$, using Balancer’s exact algebraic swap formulas for efficiency.


## Balancer Math Outline


Balancer’s weighted pool math generalizes the constant-product AMM for multi-asset pools (up to 8 assets), using a weighted invariant. It supports pairwise swaps with exact algebraic formulas, optimized with fixed-point log/exp functions.


### Key Formulas


- **Invariant**:

  $$
  \prod_i (R_i^{w_i}) = k
  $$

  where $R_i$ is the reserve of asset $i$, and $w_i$ is the normalized weight:

  $$
  \sum_i w_i = 1
  $$

- **Spot Price** (asset $i$ to $j$):

  $$
  p_{i \to j} = \frac{w_j}{w_i} \cdot \frac{R_j}{R_i}
  $$

- **Swap Quantity Out** (input $\Delta A_{\text{in}}$ of asset A, output $\Delta B_{\text{out}}$ of asset B, fee $\gamma = 0.997$):

  $$
  \Delta B_{\text{out}} = R_B \cdot \left( 1 - \left( \frac{R_A}{R_A + \Delta A_{\text{in}} \cdot \gamma} \right)^{\frac{w_A}{w_B}} \right)
  $$

- **Swap Cost In** (output $\Delta B_{\text{out}}$):

  $$
  \Delta A_{\text{in}} = R_A \cdot \left( \left( \frac{R_B}{R_B - \Delta B_{\text{out}} \cdot \gamma} \right)^{\frac{w_A}{w_B}} - 1 \right)
  $$

- **Updates**: Adjust reserves ($R_A += \Delta A_{\text{in}}$, $R_B -= \Delta B_{\text{out}}$) to preserve $k$.

- **Optimizations**: Uses log/exp via `FixedPoint.sol` for powers, ensuring O(1) swaps. Reserve updates may touch all assets (O(n) worst-case).

- **Reference**: Balancer Labs, "Balancer V2 Whitepaper," 2021. [docs.balancer.fi](https://docs.balancer.fi/v2/core-concepts/protocol/whitepaper); `WeightedMath.sol` [GitHub](https://github.com/balancer-labs/balancer-v2-monorepo).


## Unweighted FPMM Math


For the FPMM, we use equal weights ($w_k = 1/n$) to match the prediction market’s uniform outcome structure, simplifying the invariant to the product of outcome reserves. Trades are against vUSDC (collateral $R_v = \min[H_k]$, weight $w_v = 1$), with $R_v$ used for pricing but not in the invariant. Unweighted formulas:


- **Invariant**:

  $$
  \prod_j R_j = k
  $$

- **Reserves**:

  - Outcome reserve $R_k$:

    $$
    R_k = H_k = v + \text{tilt}[k]
    $$

    Queried from the ledger’s $H_k$ (effective virtual shares).

  - vUSDC collateral $R_v$:

    $$
    R_v = \min_k H_k
    $$

    Queried as the minimum $H_k$ across outcomes (withdrawable collateral), used for pricing.

- **Spot Price** (Back $k$ in vUSDC):

  $$
  p_k = \frac{w_v}{w_k} \cdot \frac{R_v}{R_k} = n \cdot \frac{\min[H_k]}{R_k}
  $$

  Lay $k$:

  $$
  l_k = 1 - p_k
  $$

  Matches $1 / (R_k \cdot S)$ when $\min[H_k] \cdot S \approx 1/n$, where:

  $$
  S = \sum_j \frac{1}{R_j}
  $$

- **Quantity Out** (buy $q$ Back $k$ with $\Delta x_{\text{in}}$ vUSDC):

  $$
  q = R_k \cdot \left( 1 - \left( \frac{\min[H_k]}{\min[H_k] + \Delta x_{\text{in}} \cdot \gamma} \right)^n \right)
  $$

- **Cost In** (buy $q$ Back $k$):

  $$
  \Delta x_{\text{in}} = \min[H_k] \cdot \left( \left( \frac{R_k}{R_k - q \cdot \gamma} \right)^n - 1 \right)
  $$

- **Lay k**:

  $$
  C_{\text{lay}}(q) = q - C_{\text{back}}(q)
  $$

- **Updates**:

  - Query $R_k = H_k$, $R_v = \min[H_k]$ from ledger.

  - Update cached:

    $$
    S = \sum_j \frac{1}{R_j}
    $$

    and scaling factor:

    $$
    \alpha_{\text{epoch}} = \alpha_{\text{epoch}} \cdot \left( \frac{R_{k,\text{old}}}{R_{k,\text{new}}} \right)^{\frac{1}{n-1}}
    $$

- **O(1)**: Exact swaps use Balancer’s log/exp, avoiding quadratic or numerical solves.


## Forking and Implementing with Ledger


Forking Balancer’s `WeightedMath.sol` adapts its unweighted math to the FPMM. The ledger tracks $H_k = v + \text{tilt}[k]$ and $\min[H_k]$ for a single market maker, handling solvency and token minting, while the AMM computes prices and requests tokens.


### Forking Steps


- **Source**: Copy `WeightedMath.sol` for `_calcOutGivenIn` and `_calcInGivenOut`.

- **Modify Weights**: Set $w_v = 1$ (vUSDC), $w_k = 1/n$ (outcomes).

- **Ledger Queries**:

  - $R_k = \text{ledger.getH}(k)$ for outcome reserves.

  - $R_v = \text{ledger.getMinH}()$ for vUSDC collateral.

- **Token Operations**:

  - Mint: `ledger.requestBack(k, q)`, `ledger.requestLay(k, q)`.

  - Burn: `ledger.depositBack(k, q)`, `ledger.depositLay(k, q)`.

- **Add State**: Store $S$ and $\alpha_{\text{epoch}}$ in AMM for O(1) pricing and lazy scaling.

- **Swap Logic**:

  - Back $k$ trades: Use Balancer’s formulas with $R_A = R_v$, $R_B = R_k$, $w_A = 1$, $w_B = 1/n$.

  - Lay $k$: $C_{\text{lay}}(q) = q - C_{\text{back}}(q)$.

  - Update:

    $$
    S = S - \frac{1}{R_{k,\text{old}}} + \frac{1}{R_{k,\text{new}}}
    $$

    $$
    \alpha_{\text{epoch}} = \alpha_{\text{epoch}} \cdot \left( \frac{R_{k,\text{old}}}{R_{k,\text{new}}} \right)^{\frac{1}{n-1}}
    $$

- **Solidity Changes**:

  - Remove reserve storage; use ledger queries.

  - Keep `FixedPoint.sol` for log/exp powers.

  - Add $S$, $\alpha_{\text{epoch}}$ for efficiency.


### Solvency


Ledger enforces:

  $$
  H_k \geq 0
  $$

and multi-winner checks:

  $$
  \text{sum of } m \text{ smallest } H_k \geq (m-1) \cdot v
  $$


### Lay Price Impact


Buying $q$ Lay $k$ increases $R_k$, reducing $S$, increasing $p_i = 1/(R_i \cdot S)$ for $i \neq k$. Inherent to constant-product coupling.


## Implementation


```solidity
struct State {
    uint256 S;           // S = sum(1/R_k)
    uint256 alpha_epoch; // Cumulative scaling factor
}

// Query R_k from ledger
function getReserve(uint256 k) internal view returns (uint256) {
    return ledger.getH(k);
}

// Query R_v = min[H_k]
function getRv() internal view returns (uint256) {
    return ledger.getMinH();
}

// Spot price for Back k
function spotPriceBack(uint256 k) public view returns (uint256) {
    uint256 R_k = getReserve(k);
    return (n * getRv()) / R_k; // Or 1 / (R_k * S)
}

// Spot price for Lay k
function spotPriceLay(uint256 k) public view returns (uint256) {
    return 1 - spotPriceBack(k);
}

// Exact cost for q Back k
function costBackExact(uint256 k, uint256 q) public view returns (uint256) {
    uint256 R_k = getReserve(k);
    uint256 R_v = getRv();
    uint256 factor = (R_k * 1e18) / (R_k - q * (1 - fee));
    uint256 power = _pow(factor, n); // Balancer’s FixedPoint.sol
    return (R_v * (power - 1e18)) / 1e18;
}

// Exact quantity for Δx_in vUSDC
function quantityBackExact(uint256 k, uint256 x_in) public view returns (uint256) {
    uint256 R_k = getReserve(k);
    uint256 R_v = getRv();
    uint256 factor = (R_v * 1e18) / (R_v + x_in * (1 - fee));
    uint256 power = _pow(factor, n);
    return R_k * (1e18 - power) / 1e18;
}

// Update after Back k trade
function updateAfterBack(uint256 k, uint256 q) internal {
    uint256 R_old = getReserve(k);
    ledger.requestBack(k, q);
    uint256 R_new = getReserve(k);
    S = S - (1e18 / R_old) + (1e18 / R_new);
    alpha_epoch = (alpha_epoch * _pow((R_old * 1e18) / R_new, 1e18 / (n - 1))) / 1e18;
}

// Update after Lay k trade
function updateAfterLay(uint256 k, uint256 q) internal {
    uint256 R_old = getReserve(k);
    ledger.requestLay(k, q);
    uint256 R_new = getReserve(k);
    S = S - (1e18 / R_old) + (1e18 / R_new);
    alpha_epoch = (alpha_epoch * _pow((R_old * 1e18) / R_new, 1e18 / (n - 1))) / 1e18;
}

// Balancer’s power function
function _pow(uint256 base, uint256 exp) internal pure returns (uint256) {
    // Use FixedPoint.sol for exp(exp * log(base))
}
```


### Notes


- **Invariant**: Excludes $R_v$; uses $\prod_j R_j = k$ for outcome reserves only.

- **R_v = \min[H_k]**: Queried via `ledger.getMinH()` for pricing, not invariant.

- **Ledger**: Queries only; no $v$, $\text{tilt}[k]$ changes.

- **Guards**: Ledger ensures $H_k \geq \varepsilon$ (0.001 vUSDC).

- **Multi-Winner**: Ledger enforces $\text{sum of } m \text{ smallest } H_k \geq (m-1) \cdot v$.

- **Performance**: O(1) via Balancer’s math; $S$, $\alpha_{\text{epoch}}$ optimize spot prices.


## References


- Angeris, Chitra, et al., "Constant Function Market Makers: Multi-asset Trades via Convex Optimization," 2021. [arXiv:2107.12484](https://arxiv.org/abs/2107.12484)

- Balancer Labs, "Balancer V2 Whitepaper," 2021. [docs.balancer.fi](https://docs.balancer.fi/v2/core-concepts/protocol/whitepaper)

- Balancer V2 Code, `WeightedMath.sol`. [GitHub](https://github.com/balancer-labs/balancer-v2-monorepo)

- Omen (Gnosis) Documentation, "Fixed Product Market Maker." [omen.eth.link](https://omen.eth.link)