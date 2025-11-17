---
comments: true
slug: glossary
title: Glossary
---

# Core Terminology

Prediction Perps defines a precise vocabulary for its non-resolving, zero-sum markets.  
These terms describe the structural units that make up all markets in the system.

---

### Market
A **Prediction Perps Market** is a self-contained trading environment that defines a set of **Positions** which share one pool of collateral.  
Each Market operates under the zero-sum invariant:

> **Σ (Position prices) = 1**

Value is presevered within each market and moves between positions.

---

### Position
A **Position** represents one **dimension of continuous exposure** within a Market  
(e.g., *Team A*, *Team B*, *Team C*).  

Together, all Positions define the structure of a Market’s zero-sum balance.

---

### Shares
A **Share** represents fractional exposure to a single Position.

- **Back Share** — exposure *to* that Position.  
- **Lay Share** — exposure *against* that Position (to all others).

---

### Tokens
**Tokens** are the on-chain representation of Shares.  
Each token corresponds to a specific type of Share (Back or Lay) for a given Position in a specific Market.

---

### Full Basket
A **Full Basket** represents **unity exposure** — exposure of 1 to every Position in the Market.  

It can be formed from any combination of Shares/Tokens that together yield +1 exposure to each Position.  
The specific composition does not matter; only the resulting exposure does.

**Examples**

- **Binary Market** (Positions A and B):  
  `{ Back_A , Back_B }` → Full Basket → **1 USDC**

- **Three-Position Market** (A, B, C):  
  `{ Back_A , Back_B , Back_C }` → Full Basket → **1 USDC**

- **Three-Position Market using fractional Lays:**  
  `{ ½ Lay_A , ½ Lay_B , ½ Lay_C }` → Full Basket → **1 USDC**

- **Mixed example:**  
  `{ Lay_A , Back_A }` → Full Basket → **1 USDC**

---

### Operations

The system defines two complementary operations that link real collateral (USDC) and Full Baskets:


#### Redemption

 — converting a **Full Basket → 1 USDC**  
  The act of collapsing unity exposure back into the fixed collateral unit. 

#### Issuance

 — converting **1 USDC → Full Basket**  
  The act of expanding the collateral unit into unity exposure across all Positions.

--8<-- "link-refs.md"
