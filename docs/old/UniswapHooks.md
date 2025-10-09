# Uniswap V4 Hooks: Quick Guide for V2 Users

## Overview
Uniswap V2 uses a fixed formula (xy = k) for pools. Uniswap V4 adds **hooks**—smart contracts that customize how pools work, keeping things flexible while feeling seamless for users.

## What Are Hooks?
Hooks are contracts linked to V4 pools at creation. They let developers add custom logic, so each pool can have unique features like dynamic fees or hedging. One hook can manage multiple pools.

## Tapping On-Chain Liquidity
Hooks let pools **use liquidity from other on-chain sources** (e.g., other DEXs or lending platforms like Aave) while users trade through a single Uniswap pool.

- **How It Works**: Hooks can pull funds from on-chain protocols to improve trade prices or depth, but users see it as one simple swap.
- **Why It Matters**: Users get better prices and more liquidity without juggling multiple platforms.
- **Example Use Case**: A hook can auto-hedge positions across two pools (e.g., buying in one pool triggers a balancing sell in another), managing risk seamlessly.

V4 hooks make pools adaptable, blending on-chain liquidity and custom features into one smooth experience.