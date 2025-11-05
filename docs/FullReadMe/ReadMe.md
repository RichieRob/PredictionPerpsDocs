# Prediction Perps — Framework Overview

Prediction Perps is a **framework for building continuous, zero-sum markets**.  
It defines a set of modular components for constructing systems where prices are internally related, liquidity is unified, and solvency is enforced by design.  

---

## 1 · What Is a Prediction Perps Market?

A Prediction Perps market is a n-dimensiona. **perpetual, zero-sum market** that can operate with **zero initial liquidity**.  
At launch, the system internally generates synthetic liquidity so that prices exist and trading can begin immediately.  

Each market contains multiple positions that together form a closed system.  
Every position represents a discrete share of a fixed total (normally 1 USDC), and all positions are priced relative to one another.  
Unlike event-based markets that close on resolution, these markets never end.  
Prices evolve continuously as traders buy and sell positions, redistributing value within the same fixed pool of capital.

This structure allows sentiment or conviction to be expressed **perpetually**, not just until an event occurs — and it allows new markets to form and function instantly, without waiting for liquidity providers.

---

# What Is a Prediction Perps Market?

A **Prediction Perps market** is a continuous, zero-sum system for expressing and trading conviction over time.  
Each market contains multiple positions that together represent a fixed total value — normally 1 USDC.  
When traders buy or sell positions, they are redistributing that fixed value between outcomes rather than creating or destroying capital.

Unlike event-based prediction markets that close on resolution, Prediction Perps markets never end.  
Prices evolve continuously as sentiment changes, and all positions remain live indefinitely.  
This allows markets to reflect **ongoing belief or performance**, rather than binary outcomes.

A unique feature of Prediction Perps is that markets can **begin operating with zero initial liquidity**.  
At launch, the system provides **synthetic liquidity** — an internal pool that behaves like real USDC, ensuring that prices exist and trades can clear immediately.  
As genuine capital enters the system, this synthetic component is automatically replaced, keeping the market solvent at all times.

---

# Prediction Perps — Framework Overview

Prediction Perps is a **framework for building continuous, zero-sum markets**.  
It defines a set of modular components that make this behaviour possible:  
markets that are always priced, internally solvent, and able to start trading with zero initial capital.

The framework combines:
- **Unified liquidity** — all positions share one pool of capital.  
- **Ledger-enforced solvency** — balances and redemptions are controlled by a central accounting layer.  
- **O(1) LMSR pricing** — prices update instantly, regardless of market size.  
- **Synthetic liquidity (ISC)** — internal credit that safely bootstraps new markets.

Together, these mechanisms allow for perpetual, capital-efficient markets that remain balanced and liquid from inception.

--



*(Then continue with System Architecture / Core Components as before.)*
