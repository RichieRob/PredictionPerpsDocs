# Logarithmic Market Scoring Rule (LMSR) for Binary Prediction Markets

## Introduction

The Logarithmic Market Scoring Rule (LMSR), developed by Robin Hanson, is a pricing mechanism for binary prediction markets with two outcomes (Yes or No, e.g., "Will it rain?"). It ensures traders can buy or sell shares anytime, with prices reflecting probabilities that sum to 100%. LMSR provides continuous liquidity and limits the market maker's financial risk while aggregating trader beliefs into accurate forecasts.

## Key Terms and Formulas

- **Yes Shares ($q_Y$)**: Total Yes shares held by users
- **No Shares ($q_N$)**: Total No shares held by users
- **Liquidity Parameter ($b$)**: A constant (e.g., 1000) set at market creation, controlling price sensitivity. Higher $b$ means less price movement per trade, creating a deeper market.
- **Maximum Liability**: The market maker's worst-case loss, equal to $b \cdot \ln(2) \approx 0.693b$. For $b = 1000$, max liability is ≈ $693
- **Cost Function ($C$)**: Tracks the total USDC committed to reach the current share distribution ($q_Y$, $q_N$) and includes the liability of the AMM. 

The **system's value excluding AMM liability is**:

  $$ \text{System Value} = C(q_Y, q_N) - C(0,0) $$

  where:

  $$ C(q_Y, q_N) = b \cdot \ln(e^{q_Y / b} + e^{q_N / b}) $$

  At $q_Y = q_N = 0$, $C(0,0) = b \cdot \ln(2) \approx 0.693b$, the baseline equal to the maximum liability, setting fair initial prices.

- **Price of Yes ($p_Y$)**: Marginal cost of one additional Yes share for a user, defined as the partial derivative of the cost function with respect to $q_Y$:
  $$ p_Y = \frac{\partial C}{\partial q_Y} = \frac{e^{q_Y / b}}{e^{q_Y / b} + e^{q_N / b}} $$

- **Price of No ($p_N$)**: Marginal cost of one additional No share for a user, defined as the partial derivative of the cost function with respect to $q_N$:
  $$ p_N = \frac{\partial C}{\partial q_N} = \frac{e^{q_N / b}}{e^{q_Y / b} + e^{q_N / b}} $$

- **Complementary Pricing**: $p_Y + p_N = 1$
- **Trade Cost**: Cost of buying $\Delta$ Yes shares:

  $$ \text{Cost} = C(q_Y + \Delta, q_N) - C(q_Y, q_N) $$

