
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





## Step 0 — Initial State
- **Synthetic depth (ISC)** = **10,000 USDC** (virtual)  
- **Real USDC** = **0**

|             | ISC (USDC) | USDC (real) | A (exp) | B (exp) | C (exp) |
|-------------|-------------|-------------|---------|---------|---------|
| **Pool**    | 10,000      | 0           | 0       | 0       | 0       |

---

## Step 1 — User 1 buys 300 **A** for **100 USDC**
- Ledger receives **+100 USDC (real)**.

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 10,000 | 0 | 0 | 0 | 0 |
| *Split ISC* | | | | | |
| **Before 2** | 9,800 | 0 | 200 | 200 | 200 |
| **After**   | 9,800 | 100 | 0 | 200 | 200 |

---

## Step 2 — User 2 buys 200 **B** for **50 USDC**
- Ledger receives **+50 USDC (real)** → total **150 USDC**.

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 100 | 0 | 200 | 200 |
| **After**   | 9,800 | 150 | 0 | 0 | 200 |

---

## Step 3 — User 3 sells 150 **A** for **80 USDC**
- Ledger pays **−80 USDC (real)** → remaining **70 USDC**.

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 150 | 0 | 0 | 200 |
| **After**   | 9,800 | 70 | 150 | 0 | 200 |

---

## Step 4 — User 4 sells 20 **B** for **15 USDC**
- Must **recapitalise ISC** up to **10,000 USDC** before merging to real USDC.

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,800 | 70 | 150 | 0 | 200 |
| **After 1** | 9,800 | 55 | 150 | 20 | 200 |
| *Merge positions — fill ISC first* | | | | | |
| **After 2** | 9,820 | 55 | 130 | 0 | 180 |

---

## Step 5 — User 5 buys 200 **Lay C** for **150 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before 1** | 9,820 | 55 | 130 | 0 | 180 |
| *Split ISC* | | | | | |
| **Before 2** | 9,620 | 55 | 330 | 200 | 380 |
| **After**   | 9,620 | 205 | 130 | 0 | 380 |

---

## Step 6 — User 6 sells 100 **Lay A** for **30 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,620 | 205 | 130 | 0 | 380 |
| **After 1** | 9,620 | 175 | 130 | 100 | 480 |
| *Merge — fill ISC first* | | | | | |
| **After**   | 9,720 | 175 | 30 | 0 | 380 |

---

## Step 7 — User 7 sells 300 **Lay C** for **150 USDC**

|             | ISC (USDC) | USDC (real) | A | B | C |
|-------------|-------------|-------------|---|---|---|
| **Before**  | 9,720 | 175 | 30 | 0 | 380 |
| **After 1** | 9,720 | 25 | 330 | 300 | 380 |
| *Merge — fill ISC first* | | | | | |
| **After 2** | 10,000 | 25 | 50 | 20 | 100 |
| *Merge — now fill real USDC* | | | | | |
| **After 3** | 10,000 | 45 | 30 | 0 | 80 |
