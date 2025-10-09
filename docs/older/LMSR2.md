# Logarithmic Market Scoring Rule (LMSR) for Binary Prediction Markets with Token Pair Minting
## Introduction
The Logarithmic Market Scoring Rule (LMSR), developed by Robin Hanson, is adapted here for a binary prediction market with two outcomes (Yes or No, e.g., "Will it rain?"). This version simplifies computations by minting Yes/No token pairs from the contract's funds, ensuring prices reflect probabilities summing to 100%. The contract is funded with its maximum liability, and tokens are minted dynamically to maintain liquidity while capping risk.

## Key Terms and Concepts
- **Yes Shares ($q_Y$)**: Total Yes tokens held by users.
- **No Shares ($q_N$)**: Total No tokens held by users.
- **Contract Holdings ($h_Y$, $h_N$)**: Yes and No tokens held by the contract, used to calculate prices and trade amounts.
- **Liquidity Parameter ($b$)**: A constant (e.g., 1000) set at market creation, controlling price sensitivity. Higher $b$ means less price movement per trade, creating a deeper market.
- **Maximum Liability**: The market maker's worst-case loss, funded upfront as $b \cdot \ln(2) \approx 0.693b$. For $b = 1000$, max liability is ≈ $693 USDC.
- **System Value**: The total USDC value of user-held tokens, derived from the contract's token holdings.
- **Price Calculation**: Prices are derived from the contract's holdings ($h_Y$, $h_N$), ensuring computational simplicity and real-time updates.

## Mechanism
The contract is initialized with $q_Y = q_N = 0$, $h_Y = h_N = b$, and funded with $b \cdot \ln(2)$ USDC. Prices start at $p_Y = p_N = 0.5$. When a user deposits USDC, the contract:
1. Mints equal Yes/No token pairs using its funds.
2. Sells the requested token type (Yes or No) to the user at a price derived from the updated holdings.
3. Adjusts $h_Y$ and $h_N$ based on the trade.

### Price Formulas
Prices are calculated based on the contract’s token holdings:
- **Price of Yes ($p_Y$)**:
  $$ p_Y = \frac{h_N}{h_Y + h_N} $$
- **Price of No ($p_N$)**:
  $$ p_N = \frac{h_Y}{h_Y + h_N} $$
- **Complementary Pricing**: $p_Y + p_N = 1$, ensuring probability summation.

### Trade Process
- **User Deposit**: A user deposits $d$ USDC to buy Yes or No tokens.
- **Pair Minting**: The contract mints $m$ pairs of Yes/No tokens, where $m$ is determined by the deposited USDC and current prices, ensuring the contract’s liability remains within $b \cdot \ln(2)$.
- **Token Sale**: The contract sells the requested tokens (e.g., $\Delta$ Yes tokens) to the user, updating $h_Y$ and $h_N$.
- **Cost Calculation**: The cost is the USDC spent ($d$), and the number of tokens received is based on the price at the time of the trade:
  $$ \Delta = \frac{d}{p_Y} \text{ (for Yes tokens)} \text{ or } \frac{d}{p_N} \text{ (for No tokens)} $$
- **Holdings Update**: For $\Delta$ Yes tokens sold, $h_Y \gets h_Y - \Delta$, $h_N \gets h_N + \Delta$ (since pairs are minted).

### Liquidity Adjustment
The contract can increase liquidity by adding more USDC (increasing $b$) and minting additional Yes/No token pairs, proportionally increasing $h_Y$ and $h_N$. This maintains price stability and ensures the liability cap scales with $b \cdot \ln(2)$.

## Example
For $b = 1000$, initial state: $q_Y = q_N = 0$, $h_Y = h_N = 1000$, $p_Y = p_N = 0.5$, contract funded with ≈ $693.15 USDC. A user deposits 9.85 USDC to buy Yes tokens:
- Contract mints $m$ Yes/No pairs (e.g., $m = 10$, adding 10 Yes and 10 No tokens, costing ≈ $10 USDC at $p_Y = 0.5$).
- Sells ≈ 19.7 Yes tokens ($9.85 / 0.5$) to the user.
- Updates: $h_Y = 1000 - 19.7 = 980.3$, $h_N = 1000 + 10 = 1010$.
- New prices: $p_Y = \frac{1010}{980.3 + 1010} \approx 0.507$, $p_N = \frac{980.3}{980.3 + 1010} \approx 0.493$.
- System Value: Value of user-held tokens (19.7 Yes tokens at $p_Y \approx 0.507$) ≈ $9.85 USDC.

## Advantages
- **Simplified Computation**: Prices are derived from token holdings ($h_Y$, $h_N$), avoiding complex logarithmic calculations in real-time.
- **Dynamic Liquidity**: Minting pairs ensures continuous trading and allows liquidity increases without disrupting prices.
- **Capped Risk**: The contract’s liability is always funded upfront at $b \cdot \ln(2)$, ensuring no excess loss.
- **Scalability**: Liquidity can be increased by adding USDC and minting more pairs, adjusting $b$ dynamically.

## Conclusion
This LMSR variant uses token pair minting to simplify pricing and maintain liquidity in binary prediction markets. By calculating prices from contract holdings, it reduces computational overhead while ensuring fair pricing and capped risk at $b \cdot \ln(2)$. The system value reflects trader investment, making it suitable for decentralized prediction markets.