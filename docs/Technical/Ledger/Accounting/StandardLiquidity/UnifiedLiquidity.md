---
comments: true
---

# Unifying Liquidity in Zero-Sum Markets

Liquidity is the quiet engine of every healthy market. It’s the reason you can sell a stock, swap a token, or bet on an election outcome without waiting days or moving the price by 20%. At its core, liquidity simply means: *someone is always ready to take the other side of your trade, at a fair and stable price.*

| **Feature**                  | **Liquid Market** | **Illiquid Market** |
|-----------------------------|-------------------|---------------------|
| Counterparty Availability   | ✅                 | ❌                  |
| Price Stability Under Trade | ✅                 | ❌                  |
| Narrow Bid-Ask Spread       | ✅                 | ❌                  |

But liquidity isn’t free. It’s **capital**—real money—sitting in the market, waiting.

---

## The Hidden Cost of Liquidity

Every system we use today **locks** that capital:

- In an **order book**, funds wait in limit orders.  
- In an **AMM**, tokens are spread across a price curve in a single pool.  
- Even Uniswap v4 requires liquidity to be deposited into *one specific pool*.

That capital can’t be used elsewhere. It’s idle. It earns nothing. And it’s **duplicated**: USDC in an ETH pool can’t help a BTC pool.

This is the silent tax on efficiency.

---

## The Dream: Unified Liquidity

What if **one pool of USDC** could back **every trade, across every market**?

No duplication.  
No idle capital.  
Liquidity flows where it’s needed—*only when it’s needed*.

This is possible in traditional systems, but only **halfway**.

You can unify the **base asset** (USDC). A single pool can serve hundreds of pairs, allocating capital dynamically. But the **counterparty assets**—the tokens or positions on the other side—stay trapped in their own markets.

Unification is **asymmetrical**.

---

## Zero-Sum Markets Change the Game

Now consider **zero-sum markets**, like prediction markets.

Here’s the breakthrough:

> **1 USDC can be split into one share of every possible outcome.**  
> **And those shares—no matter their price—can always be recombined into exactly 1 USDC.**

- Binary event? → 1 Yes + 1 No = 1 USDC  
- Four-way election? → 1 share in each candidate = 1 USDC  

Outcome shares aren’t separate assets. They’re **fractional claims on the same collateral**. They’re *perfectly fungible with each other*.

This creates **symmetry**.

---

## Symmetry Enables Full Unification

In a zero-sum market:

- The **base asset** (USDC) is already in a shared pool.  
- The **counterparty assets** (outcome shares) **reunify** into that same USDC.

Now **both sides of every trade** are made of the **same unified resource**.

A market maker no longer needs separate capital to sell Yes or buy No. The **same USDC** can counter **any trade**, in **any direction**, across **any market**.

---

## One Pool to Rule Them All

There is **one shared collateral pool**—USDC.

That’s it.

- Trades create **net exposure** (e.g., more Yes than No).  
- The pool funds only that **imbalance**.  
- When opposing trades arrive, a **complete set** forms.  
- That set is **burned instantly**.  
- The full 1 USDC per set returns to the pool.

Capital is **never locked in a position**. It’s only held against **net open exposure**. Balanced positions self-destruct and recycle their collateral immediately.

---

## The Ultimate Upgrade: Earn While You Wait

Here’s where it gets powerful.

Because capital is **only locked in net exposure**, and **complete sets vanish**, the **vast majority of the pool sits idle at any moment**—but now, that “idle” is an illusion.

The **entire unified USDC pool can be deposited into Aave, Compound, or any yield-bearing vault**.

- Interest accrues on the **full pool**, minus only the small fraction tied to net exposure.  
- When a trade needs liquidity, USDC is **withdrawn on-demand**—just like a line of credit.  
- When sets burn, USDC flows **back in**, re-earning yield instantly.

Liquidity providers no longer choose between **earning yield** and **providing liquidity**.

They do **both**, at scale, with **one shared, interest-bearing pool**.

---

## The New Reality

| **Old World**                   | **Unified Zero-Sum World** |
|---------------------------------|----------------------------|
| Siloed pools                    | One pool, all markets      |
| Capital duplicated              | Zero duplication           |
| Idle = wasted                   | Idle = earning yield       |
| Asymmetrical liquidity          | Fully symmetrical          |
| LPs pick: yield *or* liquidity  | LPs get **both**           |

Liquidity becomes a **system-wide utility**—like electricity in a smart grid. It flows. It earns. It scales.

---

## Why This Matters

- A platform with 10,000 prediction markets each with 100 positions has 2,000,000 different tokens. Liquidity for all these positions can be provided by one pool. 
- LPs earn **real yield** on nearly 100% of their capital.  
- Traders get **deep, instant liquidity** with zero slippage from fragmentation.  
- Capital efficiency hits levels never seen in DeFi.

---

## In Short

Zero-sum markets + unified collateral + yield-bearing pools = **liquidity without compromise**.

> **One pool. All markets. Earning yield. Only drawn when needed.**


## Example: Internal Accounting of Collateral

In these examples, we show explicit splitting of collateral into shares.  
Note that this is simply a way of conveying the internal accounting of a ledger,  
rather than an explicit split of tokens.

---

## Example Trades

### Initial State

The pool begins with **100 USDC**.

**Market 1** has four positions: **A**, **B**, **C**, and **D**.

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Initial State**     | 100  | 0  | 0  | 0  | 0  |


---

### User Buys 20 **A** Shares for **5 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 100  | 0  | 0  | 0  | 0  |
| *Split USDC*   |      |    |    |    |    |
| **Before 2**   | 80   | 20 | 20 | 20 | 20 |
| **After**      | 85   | 0  | 20 | 20 | 20 |

---

### User Buys 30 **B** Shares for **3 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 85   | 0  | 20 | 20 | 20 |
| *Split USDC*   |      |    |    |    |    |
| **Before 2**   | 75   | 10 | 30 | 30 | 30 |
| **After**      | 78   | 10 | 0  | 30 | 30 |

---

### User Sells 20 **C** Shares for **6 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 78   | 10 | 0  | 30 | 30 |
| **After**      | 72   | 10 | 0  | 50 | 30 |

---

### User Buys 100 **D** Shares for **50 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 72   | 10 | 0  | 50 | 30 |
| *Split USDC*   |      |    |    |    |    |
| **Before 2**   | 2   | 80 | 70 | 120 | 100 |
| **After**      | 52  | 80 | 70 | 120 | 0  |

---

## Example: Lay Trades

**Note:** *Laying A* is equivalent to *backing B, C, and D.*

---

### User sells 20 **Lay A** Shares to the Pool for **12 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 52  | 30 | 20 | 70 | 0  |
| *After 1*      | 40   | 30 | 50 | 90 | 20 |
| *Merge*        |      |    |    |    |    |
| **After 2**    | 60  | 10 | 20 | 70 | 0  |

---

### User buys 10 **Lay B** Shares from the Pool for **7 USDC**

|                | USDC | A | B | C | D |
|----------------|------|---|---|---|---|
| **Before**     | 60  | 10 | 20 | 70 | 0  |
| *Split*        |      |    |    |    |    |
| **Before 2**   | 50  | 20 | 30 | 80 | 10 |
| **After**      | 57  | 10 | 30 | 70 | 0  |

---

These examples illustrate how the ledger internally accounts for collateral and shares during trading, without any real “splitting” of the underlying pool.


## Further Reading
For a deeper look at implementation see [**Ledger Overview**](./LedgerOverview.md)