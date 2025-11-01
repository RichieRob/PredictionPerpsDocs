
# Synthetic Liquidity

## Overview

Synthetic liquidity gives each market the ability to trade immediately — even before any real capital has been deposited.

When a new market is created, the **official market maker** is assigned a fixed quantity of **synthetic internal liquidity**.  
This liquidity is not a real balance or a token. It does not represent money and cannot be withdrawn.  
Instead, it defines the *depth* of the market’s pricing curve — allowing the market maker to quote buy and sell prices from the first block.

In effect, the market behaves as if it already holds an evenly balanced inventory of every outcome, so traders can begin buying and selling without waiting for deposits or external liquidity providers.

---

## Purpose

- **Bootstraps trading.** Markets can open instantly, with defined prices and spreads.
- **Supports discovery.** Early buyers and sellers see meaningful quotes instead of empty books.
- **Avoids capital lockup.** No real USDC is required until the first user trade brings real funds in.

---

## Behaviour

- When users buy or sell, they pay and receive **real USDC**.
- The AMM’s internal price function references the synthetic depth to shape the curve.
- The synthetic depth itself never changes after market creation.

---

## Key Properties

| Property | Description |
|-----------|--------------|
| **One-time initialization** | Seeded once, when the market is created. |
| **Immutable** | The synthetic depth value cannot be changed or withdrawn. |
| **Official market maker only** | Only the designated market maker for each market uses synthetic liquidity. |
| **Pricing-only effect** | It determines how smooth or deep prices feel when trading begins. |

---

## Conceptual Summary

Synthetic liquidity is a **virtual cushion** — a mathematical construct that lets markets trade smoothly from the start.  
It gives the AMM something to quote against before any real deposits arrive, but all eventual settlements and payouts always occur in real USDC.

---


## Example Trades with synthetic liquidity


### Initial State
- **Synthetic depth (ISC)** = **10,000 USDC** (virtual)  
- **Real USDC** = **0**

|             | ISC (USDC) | USDC (real) | A (exp) | B (exp) | C (exp) |
|-------------|-------------|-------------|---------|---------|---------|
| **Pool**    | 10,000      | 0           | 0       | 0       | 0       |

---

### User buys 200 **A** for **100 USDC**


|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 10,000 | 0 | 0 | 0 | 0 |
| *Split ISC* | | | | | |
| **Before 2** | 9,800 | 0 | 200 | 200 | 200 |
| **After**   | 9,800 | 100 | 0 | 200 | 200 |

---

### User buys 200 **B** for **50 USDC**


|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 100 | 0 | 200 | 200 |
| **After**   | 9,800 | 150 | 0 | 0 | 200 |

---

### User sells 150 **A** for **80 USDC**


|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 150 | 0 | 0 | 200 |
| **After**   | 9,800 | 70 | 150 | 0 | 200 |

---

### User sells 20 **B** for **15 USDC**


|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 70 | 150 | 0 | 200 |
| **After 1** | 9,800 | 55 | 150 | 20 | 200 |
| **Merge — fill ISC first** | | | | | |
| **After 2** | 9,820 | 55 | 130 | 0 | 180 |

---

### User buys 200 **Lay C** for **150 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before 1** | 9,820 | 55 | 130 | 0 | 180 |
| **Split ISC** | | | | | |
| **Before 2** | 9,620 | 55 | 330 | 200 | 380 |
| **After**   | 9,620 | 205 | 130 | 0 | 380 |

---

### User sells 100 **Lay A** for **30 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,620 | 205 | 130 | 0 | 380 |
| **After 1** | 9,620 | 175 | 130 | 100 | 480 |
| *Merge — fill ISC first* | | | | | |
| **After**   | 9,720 | 175 | 30 | 0 | 380 |

---

### User sells 300 **Lay C** for **150 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,720 | 175 | 30 | 0 | 380 |
| **After 1** | 9,720 | 25 | 330 | 300 | 380 |
| *Merge — fill ISC first* | | | | | |
| **After 2** | 10,000 | 25 | 50 | 20 | 100 |
| *Merge — now fill real USDC* | | | | | |
| **After 3** | 10,000 | 45 | 30 | 0 | 80 |
