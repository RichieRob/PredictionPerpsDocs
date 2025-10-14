# Football Perps Specification

## Overview
FootballPerps is the flagship product of PredictionPerps and the pioneer in a groundbreaking new asset class - Perpetual Prediction Markets! FootballPerps enables users to buy and sell perpetual positions on the performance of football teams.

## Purpose of Perpetual Prediction Markets
- A fun new mechanism for speculation.
- Removes centralisation from prediction markets.
- Introduce a perpetual asset class.
- Create a new crypto primitive that can be built upon.
- Allow the full range of DeFi products to be used in conjunction with prediction markets.
- Allow Centralised Exchanges to sell prediction tokens.

## PredictionPerps Roadmap
- Integrate FootballPerps with the DeFi ecosystem including leveraged perpetuals, order books, and additional derivatives.
- Develop Perpetual Prediction Markets in other sports, events, or asset classes, creatinag a scalable, versatile ecosystem for PredictionPerps’ future products.

## How It Works
- **Take a Position**: Buy bullish or bearish shares on football teams using USDC. These shares reflect your view on whether a team’s performance will rise or fall, allowing profits from buying low and selling high.
- **Earn Daily Rewards**: Receive native FootballPerps tokens daily based on your team’s recent game results. Stronger performance rewards bullish holders, while weaker performance benefits bearish holders, driving dynamic price shifts and enabling profit through token accumulation.
- **No Loss from Interest**: Tokens are backed by interest generated through Aave, ensuring users don’t lose out, unlike traditional prediction markets.
- **Powered by DeFi**: Uniswap liquidity pools and Aave ensure a stable, efficient market, with the FootballPerps frontend optimizing trades, especially for large purchases.
- **Distributed and Timeless**: As a distributed protocol, shares never expire and can be traded across the entire crypto ecosystem, maximizing access and liquidity.
- **Premier League and Championship**: Starts with markets for all Premier League teams.

FootballPerps blends the excitement of football with decentralized finance, creating boundless opportunities for speculation and innovation.

## Components
- **Shares**: Users can hold bullish or bearish shares representing their position on a football team’s performance, purchased using USDC or USSD via FootballPerps-managed interactions with Uniswap liquidity pools.
- **Funding Mechanism**: FootballPerps distributes native perp payment tokens daily based on team performance metrics, backed by interest generated on USDC held by FootballPerps through Aave.
- **Team Performance Tracking**: Tracks rolling cumulative point scores over the last 38 games for Premier League teams (with adjustment for Championship teams).
- **Perp Payment Tokens**: Native tokens distributed daily to share holders, backed by interest on USDC held by FootballPerps, with potential market floatation and additional utility (e.g., burning for governance tokens).
- **USSD Stablecoin**: A stablecoin pegged 1:1 with USDC through minting and burning mechanisms.
- **Liquidity Pools**: Two liquidity pools (bullish USSD and bearish USSD) on Uniswap provide synthetic liquidity for trading bullish and bearish shares, utilized by FootballPerps to facilitate trades, with imbalances equalized by arbitrage bots.
- **Frontend Algorithm**: An algorithm that optimizes the buy/sell path for users, providing the best execution (especially for large purchases) by leveraging four bidirectional operations to execute trades through FootballPerps, without direct user access to Uniswap liquidity pools:
  - USDC<->USSD: Contract-based minting or burning of USSD to maintain a 1:1 peg with USDC.
  - USSD<->bullish,bearish pair: Minting or burning a pair of bullish and bearish shares for 1 USSD.
  - USSD<->bullish pool: Swapping USSD for bullish shares (or vice versa) via the Uniswap bullish USSD pool.
  - USSD<->bearish pool: Swapping USSD for bearish shares (or vice versa) via the Uniswap bearish USSD pool.
- **Further components TBD**: Based on Championship adjustment details, token management, and platform implementation.

## Functionality
- **Position Types**:
  - Users can take perpetual bullish (expecting team performance to rise) or bearish (expecting team performance to decline) positions on football teams.
  - Positions are represented as shares, split into bullish and bearish categories, similar to Polymarket’s share system.
  - Users purchase bullish or bearish shares using USDC, which can be converted to USSD for FootballPerps-managed interactions with Uniswap liquidity pools.
- **Funding Mechanism**:
  - For Premier League teams, FootballPerps uses a rolling cumulative point score from a team’s last 38 games. The bullish ratio is calculated as the cumulative point score divided by 114 (38 games × 3 points per game). The bearish ratio is calculated as 1 minus the bullish ratio.
  - For Championship teams, a discount factor (e.g., 1/5) is applied to points to reflect their lower value compared to Premier League points.
  - The bearish ratio is capped at a maximum of 0.93 (equivalent to a minimum bullish ratio of 0.07, or approximately 8 points in the Premier League and 40 points in the Championship after discounting), preventing teams in terminal decline from draining FootballPerps liquidity.
  - Each day, holders of bullish shares receive perp payment tokens proportional to the bullish ratio.
  - Each day, holders of bearish shares receive perp payment tokens proportional to the bearish ratio.
  - **NB**: For teams relegated to the Championship, FootballPerps may use a 46-game rolling window (reflecting the Championship’s season length) instead of a 38-game window, with adjustments needed to account for the different league structure (details TBD).
  - For teams relegated from the Championship, tracking of games ceases, as their discounted points cannot exceed the 0.07 bullish ratio threshold.
- **Perp Payment Tokens**:
  - Tokens are native to FootballPerps and backed by the interest generated on USDC held by FootballPerps through Aave, establishing a floor price.
  - Tokens may be floated on the market, possibly introducing additional utility, such as burning tokens to acquire governance tokens.
  - *Details on token distribution mechanics and governance token functionality TBD.*
- **Interest Generation**:
  - FootballPerps holds USDC paid by users to open bullish or bearish positions.
  - Interest on USDC is generated using Aave, which backs the perp payment tokens.
  - *Details on Aave integration, security, and reliability mechanisms TBD.*
- **USSD Stablecoin and Liquidity Pools**:
  - USSD is a stablecoin pegged 1:1 with USDC through minting and burning mechanisms.
  - At t=0, two liquidity pools are created on Uniswap: bullish USSD and bearish USSD. The pools are initialized with a depth (D) and a weighting factor (W) to set the starting price. For example, with D = 10,000 and W = 0.8, the bullish pool contains 10,000 bullish shares against 8,000 USSD, and the bearish pool contains 10,000 bearish shares against 2,000 USSD, establishing synthetic liquidity.
  - A pair of bullish and bearish tokens can be minted or burned for 1 USSD, capping the price of bullish and bearish shares between 0 and 1.
  - Users buy or sell shares through FootballPerps, which utilizes Uniswap’s bullish and bearish USSD liquidity pools to execute trades. Direct interaction with Uniswap pools is suboptimal, while the FootballPerps frontend provides optimal execution, especially for large purchases.
  - The Uniswap liquidity pools are open to the broader crypto ecosystem, allowing anyone to buy tokens directly, with imbalances quickly equalized by arbitrage bots.
  - A frontend algorithm optimizes the buy/sell path for users by leveraging four bidirectional operations:
    - USDC<->USSD: Contract-based minting or burning of USSD to maintain a 1:1 peg with USDC.
    - USSD<->bullish,bearish pair: Minting or burning a pair of bullish and bearish shares for 1 USSD.
    - USSD<->bullish pool: Swapping USSD for bullish shares (or vice versa) via the Uniswap bullish USSD pool.
    - USSD<->bearish pool: Swapping USSD for bearish shares (or vice versa) via the Uniswap bearish USSD pool.
  - Arbitrage prevention is handled through optimized mechanisms via the frontend, ensuring efficient trading.

## Scope
- FootballPerps supports positions on teams in the English Premier League and the Championship, with initial markets covering current Premier League teams.
- FootballPerps accommodates teams relegated from the Premier League, allowing positions on non-Premier League teams over time.