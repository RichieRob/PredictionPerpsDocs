# How to Implement a CAMM Behind a Uniswap V4 Hook

## Integration Mechanism
- **CAMM**: Calculates buy and sell prices for all composite market tokens (e.g., BackLiverpool, LayLiverpool, BackManchesterCity) using a single pricing model (e.g., LMSR or custom). It manages liquidity to fulfill trades across the market, including token-to-token swaps.
- **Uniswap V4 Hook**: A smart contract linked to Uniswap V4 pools at creation, routing trade requests from each pool (e.g., USDC/BackLiverpool, BackLiverpool/BackManchesterCity) to the CAMM for pricing and fulfillment.

## Flow: USDC → Composite Market Token (e.g., BackLiverpool)
1. A user sends USDC to a Uniswap pool to buy BackLiverpool tokens.
2. The hook routes the trade details (USDC amount, requested token) to the CAMM.
3. The CAMM calculates the price for BackLiverpool tokens and provides them from its liquidity.
4. The CAMM sends BackLiverpool tokens to the hook.
5. The hook settles the trade via Uniswap, delivering BackLiverpool tokens to the user.

## Flow: Composite Market Token → USDC (e.g., BackLiverpool)
1. A user sends BackLiverpool tokens to a Uniswap pool to receive USDC.
2. The hook routes the trade details (token amount, requested USDC) to the CAMM.
3. The CAMM calculates the price for BackLiverpool tokens and provides USDC from its liquidity.
4. The CAMM sends USDC to the hook.
5. The hook settles the trade via Uniswap, delivering USDC to the user.

## Flow: Composite Market Token → Composite Market Token (e.g., BackLiverpool → BackManchesterCity)
1. A user sends BackLiverpool tokens to a Uniswap pool to receive BackManchesterCity tokens.
2. The hook routes the trade details (input token amount, input token, output token) to the CAMM.
3. The CAMM calculates the effective price between BackLiverpool and BackManchesterCity tokens and provides BackManchesterCity tokens from its liquidity.
4. The CAMM sends BackManchesterCity tokens to the hook.
5. The hook settles the trade via Uniswap, delivering BackManchesterCity tokens to the user.