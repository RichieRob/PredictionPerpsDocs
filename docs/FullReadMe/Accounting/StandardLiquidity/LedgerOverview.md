# Ledger Overview

## 1. The Market Maker and Its Budget

Every market begins with a **market maker** — the participant who provides the liquidity that allows trading to happen.

The market maker sets aside a **USDC budget** for the market.  
This budget is the capital that supports trading and **makes sure there is always a price**.

The ledger’s job is to hold that capital inside the system, enforce solvency rules, and keep every operation consistent.  
It prevents the market maker from issuing more exposure than its budget allows.

---

## 2. The Balance Array

When the market maker deposits their **USDC budget**, that deposit forms the **balance array** — the record of the market maker’s assets inside the system.

The balance array can be viewed in two complementary ways:

- **As USDC** — real, withdrawable capital.  
- **As potential shares** — the capacity to issue exposure across the market.

The balance array exists in a **superposition** of these two potentials.  
It is not split or converted — it can be seen both as capital and as exposure at the same time.

Because of this design, the same balance can seamlessly emit or receive **USDC** and **position tokens** without any transformation.  
When either flows in or out, the ledger updates the array — keeping everything in perfect accounting balance.

---

## 3. Position Tokens — How Exposure Is Expressed

Each market contains a set of **positions**

For every position, there are two sides:

- **Back A** — exposure toward position A.  
- **Lay A** — exposure against position A.

Where Lay follows a fixed identity:

- \( \text{Lay}(A) = 1 - \text{Back}(A) \)  

or equivalently

-  \( \text{Lay}(A) = \sum_{i \ne A} \text{Back}(i) \)


The ledger uses this second identity to records all exposure in **Back** form.
When a market maker deposits or withdraws **Lay A**, it updates the Back entries for every other position.

---

## 4. How the Ledger Records Movements

To see how the ledger tracks potential, imagine a market with **four positions** — A, B, C, and D — and a market maker who begins by depsiting 5 USDC.

**Starting state**

| Position | potential shares |
|---------:|:-----------------|
| A        | 5                |
| B        | 5                |
| C        | 5                |
| D        | 5                |

### a) Withdraw one **Back A** token

The market maker instructs the ledger to send out 1 Back A token.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 4  (-1)              |
| B        | 5                |
| C        | 5                |
| D        | 5                |

### b) Deposit one **Back A** token

The market maker receives 1 Back A token and sends it back to the ledger.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 5   (+1)             |
| B        | 5                |
| C        | 5                |
| D        | 5                |

### c) Withdraw one **Lay A** token

The market maker instructs the ledger to emit 1 Lay A token.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 5                |
| B        | 4     (-1)           |
| C        | 4     (-1)           |
| D        | 4     (-1)           |

### d) Deposit one **Lay A** token

The market makter receives 1 Lay A token and sends it back to the ledger.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 5                |
| B        | 5       (+1)         |
| C        | 5       (+1)         |
| D        | 5       (+1)         |

### e) Deposit **1 USDC**

The market maker receives 1 USDC and sends it back to the ledger.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 6       (+1)         |
| B        | 6       (+1)         |
| C        | 6       (+1)         |
| D        | 6       (+1)         |

### f) Withdraw **1 USDC**

THe market maker withdaws 1 USDC from the ledger and sends it somewhere.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 5     (-1)           |
| B        | 5     (-1)           |
| C        | 5     (-1)           |
| D        | 5     (-1)           |

**What this shows**

- **Position tokens** chaing the balance of the array.  
- **USDC flows** expand or contract the array *as a whole*.  


---

## 5. Buys and Sells

### Buying Tokens

1. The **user sends USDC** to the market maker.  
2. The **market maker deposits** that USDC into the ledger.  (e)
3. The **market maker withdraws tokens** from the ledger and transfers them to the user.  (a/c)

---

### Selling Tokens

1. The **user sends tokens** to the market maker.  
2. The **market maker deposits** those tokens into the ledger.  (b/d)
3. The **market maker withdraws USDC** from the ledger and transfers it to the user.  (f)

---

## 6. Implementation Note

This document provides a **conceptual overview** of how accounting operates within the ledger.

### On-Chain Implementation
In the **on-chain implementation**, several optimizations are applied for efficiency, particularly when handling **Lay tokens**. Instead of updating the entire balance array, Lay accounting adjusts only the **global balance** and the **relevant Back token balance**. For a complete explanation of these implementation details, refer to the [LedgerAccounting](LedgerAccounting.md) document.

### Market Maker Constraints
The ledger ensures that a market maker never issues more tokens than its available potential. To enforce this, it continuously tracks the **minimum balance value** within the array, along with the **position** where that minimum occurs. Efficiently maintaining this information across large arrays is non-trivial and is described in detail in the [HeapLogic](../../HeapLogic.md) document.

## Further Reading
For a deeper look at the full implementation of these principals see [**Ledger Accounting**](./LedgerAccounting.md)