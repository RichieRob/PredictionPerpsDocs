# New Ideas for Tokenizing Perpetual Bounded Phenomena

## 1. Simplifying with Annual Binary Outcomes

To make development easier and the system more understandable, shift from continuous or frequent updates to annual binary outcomes. Instead of tracking rolling windows or frequent events, focus on yearly yes/no results for specific milestones.

### Key Changes:
- **Binary Nature**: Outcomes are binary (e.g., achieved or not achieved) and evaluated annually.
- **Examples in Football**:
  - Liverpool wins the Premier League.
  - Liverpool qualifies for Champions League.
  - Liverpool qualifies for Europe (Champions or Europa League).
  - Liverpool remains in the Premier League.
- **Dividend Payouts**: Dividends are paid based on the current status of the outcome. If the binary condition is met (e.g., team achieves the milestone), token holders receive yields; otherwise, no yields until the next evaluation.
- **Long-Term Holding Incentive**: Users can buy tokens for unlikely or long-shot outcomes (e.g., a lower-division team like Northampton Town reaching the Premier League). These tokens may yield nothing for years but could generate significant annual dividends (e.g., turning a $100 investment into $500/year in yields) once the outcome is achieved.

### Benefits:
- Fewer oracle events (annual updates only).
- Simpler to implement and explain, reducing complexity compared to perpetual or rolling PBPs.

This approach maintains the perpetual aspect but ties yields to discrete, annual checkpoints, making it more accessible for users and developers.

## 2. Claimable Rewards

Native yield issuance without claiming poses challenges, especially with multiple tokens yielding in the same stablecoin (e.g., USDC). To address this, introduce claimable rewards to simplify yield distribution.

### Key Points:
- **Claimable Yields**: Yields are not automatically distributed but must be claimed by token holders. This avoids building complex systems for handling yields across many tokens in the same asset.
- **Implementation**: Yields are accumulated in USDC (or a yield-bearing version like ppUSDC) and can be claimed by holders of T or \(\overline{T}\) based on the performance rubric.

### Benefits:
- Simplifies yield management for users and reduces system complexity.
- Ensures scalability when managing multiple token pairs.

## 3. Rebasing Tokens as an Additional Development

As an additional feature to support users who prefer automated yield handling, introduce rebasing tokens for auto-compounding yields on top of the base system.

### Key Points:
- **Rebasing Tokens**:
  - Users deposit base tokens (T or \(\overline{T}\)) into a rebasing contract to receive rebasing versions (e.g., aT for auto-compounding T).
  - The contract holds the base tokens and accumulates claimable interest (in USDC or ppUSDC).
  - Deposits and withdrawals of T or \(\overline{T}\) trigger a swap on Uniswap to convert accumulated interest (USDC or \(\overline{T}\)) into the deposited token type (e.g., depositing T triggers swapping \(\overline{T}\) or USDC to T). This ensures the contract maintains a balanced pool for aT holders while leveraging Uniswap’s market pricing.
  - **Deposit and Withdrawal Handling**:
    - **Deposits**: Users deposit T or \(\overline{T}\), and the contract mints aT based on a share price (`total_underlying / total_aT_supply`). The share price accounts for held T, \(\overline{T}\) (valued at Uniswap’s current price), and USDC (valued as mintable T + \(\overline{T}\) sold on Uniswap). Deposits trigger a Uniswap swap to convert any \(\overline{T}\) or USDC to T (or vice versa for \(\overline{T}\) deposits), maintaining pool balance.
    - **Withdrawals**: Redeeming aT returns T or \(\overline{T}\) based on the share price. If insufficient T is available, the contract swaps \(\overline{T}\) or USDC to T on Uniswap to fulfill the withdrawal.
    - This prevents overpayment for new depositors by ensuring they receive a fair share of the contract’s current value, adjusted for Uniswap’s market rates.
  - The contract periodically claims USDC yields, splits them into T and \(\overline{T}\), and uses Uniswap swaps to align holdings with deposited token types.

### Benefits:
- Enables auto-compounding via rebasing for hands-off users, simplifying the user experience.
- Simplifies valuation by relying on Uniswap’s market pricing, avoiding complex internal pricing algorithms.

## 4. Internal Liquidity as a Positive Externality

The rebasing contract, by facilitating the conversion of T to \(\overline{T}\) (or vice versa) via Uniswap swaps, also serves as a liquidity provider, creating a positive externality for the system.

### Key Points:
- **Liquidity Provision**:
  - The rebasing contract supports swaps between T and \(\overline{T}\) by leveraging Uniswap for conversions, triggered by deposits or withdrawals. For example, depositing T may require swapping \(\overline{T}\) or USDC to T on Uniswap to maintain pool balance.
  - **General Principle**: When a swap is needed, the contract uses Uniswap’s current market price (potentially with a TWAP for stability) to execute trades. This ensures liquidity for users while aligning the contract’s holdings with user deposits.
  - This creates a balanced, automated market within the contract, improving the liquidity of the system.
- **Positive Externality**: The need to manage complementary tokens (T and \(\overline{T}\)) inherently provides liquidity to the system by facilitating Uniswap-based trades, enhancing market depth and accessibility.

### Benefits:
- Enhances liquidity through Uniswap integration, leveraging external market efficiency.
- Creates a self-sustaining system where token conversion supports overall market efficiency.

### Handling Deposits and Withdrawals with Uniswap Integration

To address the concern about overpayment when depositing into the rebasing contract (e.g., if significant interest has accumulated), the system uses a share-based model with Uniswap swaps to ensure fairness:



- **Deposit Process**:
  - On T deposit, the contract claims accumulated USDC yields and swaps for T and \(\overline{T}\).
  - The contract swaps \(\overline{T}\) to T on Uniswap.
  - This updates user balances of aT
  - Mint aT = deposited T
  

- **Withdrawal Process**:
  - Claim accumulated ppUSDC
  - Update balances of aT
  - Burn aT being withdrawn
  - transfer amount of T equalt to aT being withdrawn to the user.

- **Benefits of Uniswap Integration**:
  - **Fairness**: Using Uniswap’s market price (or TWAP) ensures new depositors don’t receive disproportionate value from accumulated interest, preventing overpayment.
  - **Simplicity**: Eliminates the need for a complex internal pricing algorithm, relying on Uniswap’s established liquidity and pricing
  - **Liquidity Boost**: Swaps triggered by deposits/withdrawals add trading volume to Uniswap pools, enhancing overall system liquidity.
  - **Trade-Off**: Uniswap prices may not always be optimal (e.g., slippage or market volatility), but TWAP usage and sufficient pool depth can mitigate this. It’s a practical trade-off for simplicity and reliability.

This approach streamlines the rebasing contract by leveraging Uniswap for pricing and liquidity, ensuring fair deposits/withdrawals while maintaining the system’s core mechanics.

