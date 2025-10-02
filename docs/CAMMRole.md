# Composite Automated Market Maker (Composite AMM) Mechanism

## Overview
The Composite Automated Market Maker (Composite AMM) is a centralized pricing system that manages buy and sell prices for multiple outcomes within a prediction market. Each outcome (e.g., Outcome A, Outcome B, Outcome C) represents a possible resolution of the market event and is backed by a stable asset, vUSDC, ensuring full collateralization. The Composite AMM coordinates with a `Composite Market Controller` to manage collateral and token minting/burning, and with a `vUSDC Controller` to handle conversions between USDC and vUSDC at a 1:1 ratio.

## Core Mechanism
- **Composite AMM**: Calculates buy and sell prices for all outcomes using a single pricing model (e.g., LMSR or a custom algorithm), ensuring consistency across the prediction market. It manages collateral by interacting with the `Composite Market Controller` for outcome token minting/burning and the `vUSDC Controller` for asset conversions.
- **Composite Market Controller**: Maintains a ledger to track all outcome positions in the prediction market, ensuring they are 100%+ collateralized with vUSDC. It handles minting or burning of outcome tokens and transfers vUSDC as requested by the Composite AMM, provided sufficient collateral is available.
- **vUSDC Controller**: Facilitates 1:1 conversions between USDC and vUSDC for the Composite AMM, enabling seamless asset management.

## Flow: USDC → Outcome Token
1. The Composite AMM receives USDC for a trade requesting tokens for a specific outcome (e.g., Outcome A).
2. The Composite AMM sends the USDC to the `vUSDC Controller`, which converts it to vUSDC at a 1:1 ratio.
3. The Composite AMM transfers the vUSDC to the `Composite Market Controller` and requests minting of Outcome A tokens.
4. The `Composite Market Controller` verifies sufficient vUSDC collateral, mints the requested Outcome A tokens, sends them to the Composite AMM, and updates its ledger.
5. The Composite AMM delivers the Outcome A tokens to complete the trade.

## Flow: Outcome Token → USDC
1. The Composite AMM receives Outcome A tokens for a trade requesting USDC.
2. The Composite AMM sends the Outcome A tokens to the `Composite Market Controller` and requests vUSDC in return.
3. The `Composite Market Controller` verifies the tokens and collateral state, burns the Outcome A tokens, sends vUSDC to the Composite AMM, and updates its ledger.
4. The Composite AMM sends the vUSDC to the `vUSDC Controller`, which converts it to USDC at a 1:1 ratio.
5. The Composite AMM delivers the USDC to complete the trade.

## Key Points
- **Centralized Pricing**: A single Composite AMM manages pricing for all outcomes in the prediction market, ensuring consistency and efficiency.
- **Solvency**: The `Composite Market Controller` guarantees that all outcome positions are fully collateralized with vUSDC.
- **Scalability**: The system supports dynamic outcomes, allowing for flexible expansion of the prediction market.

This Composite AMM setup provides a secure and consistent pricing mechanism for prediction markets, with all collateral (vUSDC) managed by the `Composite Market Controller` to ensure system integrity.