# Token Rebasing System Specification

This document outlines the design for a token rebasing system integrated with binary event resolution using UMA bonds and Uniswap V2 pools. The system simplifies event settlement and incentivizes frequent rebalancing through a dual-token mechanism with `T`, `T-bar`, `aT`, and `aT-bar` tokens, managed by a controller contract.

## Binary Event Resolution

### Overview
The system reduces complex phenomena to binary events with long-term outcomes, settled via UMA bonds for simplified implementation.

### Key Points
1. **Event Structure**:
   - Binary events are defined with clear, verifiable outcomes.
   - Example: "The most recent football season ended with the last match day on May 11th, 2025."
   - Derived statement: "Liverpool won the Premier League Football season that ended on May 11th, 2025."
2. **UMA Integration**:
   - Binary events are pushed to UMA for resolution, leveraging UMA bonds to ensure reliable settlement.

## Rebasing Token Mechanism

### Core Concepts
The rebasing system uses two primary tokens, `T` and `T-bar`, with their respective rebasing tokens `aT` and `aT-bar`. USDC serves as the reward and exchange currency, with Uniswap V2 pools facilitating liquidity and rebalancing. A controller contract manages the minting and distribution of tokens during rebalancing.

### Token Mechanics
1. **Rewards**:
   - Rewards are claimable in USDC for holders of token `T` and `T-bar`.
   - Uniswap V2 pools exist for:
     - USDC/`T`
     - USDC/`T-bar`
   - Exchange rates:
     - 1 USDC is exchangeable for 1 `T` or 1 `T-bar`.
     - Burning 1 `T` and 1 `T-bar` yields 1 USDC.
2. **Deposits and Withdrawals**:
   - Deposit `T` to receive `aT` at a 1:1 ratio.
   - Deposit `T-bar` to receive `aT-bar` at a 1:1 ratio.
   - Burn `aT` to receive `T` at a 1:1 ratio.
   - Burn `aT-bar` to receive `T-bar` at a 1:1 ratio.

### Rebalance Process
The `Rebalance()` function manages the rebasing process between the `aT` and `aT-bar` contracts, utilizing Uniswap V2 TWAP and the `T/T-bar` controller contract. The function can be called by anyone, with incentives to increase call frequency as locked value grows.

1. **USDC Claim and Transfer**:
   - The `aT` contract claims USDC and transfers it to the controller.
   - The `aT-bar` contract claims USDC and transfers it to the controller.
2. **TWAP Calculation**:
   - The `aT` contract uses TWAP since the last rebalance to calculate the amount of `T` it should receive for its USDC (denoted as value `b`).
   - The `aT-bar` contract uses TWAP since the last rebalance to calculate the amount of `T-bar` it should receive for its USDC (denoted as value `c`).
3. **Minting and Rebasing**:
   - The controller mints `min(b, c)` pairs of `T` and `T-bar` using the USDC it holds, depositing claimed USDC into the `T/T-bar` controller contract.
   - Minted `T` is sent to the `aT` contract, and minted `T-bar` is sent to the `aT-bar` contract.
   - After minting, either the `aT` or `aT-bar` contract retains residual USDC, as only the minimum of `b` and `c` is minted.
4. **Rebalancing with TWAP Threshold**:
   - The contract rebases against Uniswap V2 using TWAP, triggered when the TWAP deviates by a predefined threshold.
   - If the TWAP threshold is not met, the contract records a new TWAP checkpoint for the next rebalance and performs a partial rebase without executing a Uniswap swap.
5. **Incentives for Rebase Calls**:
   - The `Rebalance()` function is permissionless, allowing anyone to call it and earn a reward. The reward is a percentage of the total USDC claimed by `aT` and `aT-bar` contracts during the rebalance. A 1% reward is likely sufficient to incentivize frequent calls. Initially, the dev team will deploy a bot to call `Rebalance()` regularly, ensuring consistent operation. As the total locked value in the system increases, the USDC reward will incentivize additional external users to trigger the function more frequently, resulting in smoother and more continuous rebasing.
6. **Deposit Pending Period**:
   - When a user deposits `T` to receive `aT` (or `T-bar` to receive `aT-bar`), the deposit is non-transferable during the period before the next rebalance, referred to as the "Pending Period." However, the deposit can be withdrawn during this period.
   - Rebasing for that specific user deposit does not begin until the respective contract (`aT` or `aT-bar`) is fully rebased (i.e., no claimable USDC remains). This means the user may miss the first rebase period (or part thereof) for their deposit.

### Additional Notes
- A full specification for the deposit rebase delay and Pending Period is available separately.
- The system ensures continuous rebalancing to maintain stability, with incentives designed to encourage frequent user-driven rebase calls, especially as the locked value grows.