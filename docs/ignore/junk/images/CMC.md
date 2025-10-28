# Composite Market Controller Contract Design

## Overview

The **Composite Market Controller** contract serves as the central manager for a prediction market system.

### Market Control Responsibilities

This contract handles creating, minting, and burning ERC-20 tokens for "back" (betting on an outcome) and "lay" (betting against an outcome) positions.

### Ledger Management Responsibilities

An internal ledger tracks positions for each market maker, ensuring non negative collateralization.

The contract supports dynamic or unknown numbers of outcomes (\( n \)) without requiring \( O(n) \) operations. It employs a gas-efficient ledger for position tracking and token issuance.

### Key Features and Advantages

#### Ledger-Based Accounting

Virtualizes market maker positions to reduce gas costs, with lazy minting/burning of ERC-20 tokens performed only when requested by the market maker. This approach minimizes unnecessary token operations - splits, merges, batch minting, leading to lower transaction fees and faster processing, and more flexibility for market makers.

#### Dynamic Outcomes

The contract accommodates arbitrary or expanding number of positions (or outcomes) without a predefined \( n \), utilizing sparse storage. This flexibility allows the system to handle evolving markets, such as those with user-generated outcomes, without performance degradation.

#### Gas Efficiency

Core operations (deposits, redemptions, mints, burns) are \( O(1) \), typically consuming ~15k–30k gas. Such efficiency makes the contract suitable for high-frequency trading environments, and for markets with many positions.

#### Non negative Collateralization

Guarantees market is fully colaterarised through guaranteeing each market maker's ledger is non negative. This ensures the system's financial integrity.

This design promotes scalability for large or unknown \( n \), optimizes gas usage, and upholds positive collateralization (\( v > 0 \)), effectively controlling the market and tracking CAMM positions.