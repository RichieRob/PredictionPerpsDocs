# Ledger Overview

## 1. The Market Maker and Its Budget

Every market begins with a **market maker** — the participant who provides the liquidity that allows trading to happen.

The market maker sets aside a **USDC budget** for the market.  
This budget is the capital that supports trading and **makes sure there is always a price**.

The ledger’s job is to hold that capital inside the system, enforce solvency rules, and keep every operation consistent.  
It prevents the market maker from issuing more exposure than its budget allows.

---

## 2. The Balance Array — One Asset, Two Potentials

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

Each market contains a set of **positions** — distinct directions that traders can take (e.g., *sentiment up*, *trend reversal*).

For every position, there are two sides:

- **Back A** — exposure toward position A.  
- **Lay A** — exposure against position A.

Lay isn’t a separate instrument — it follows a fixed identity:

- \( \text{Lay}(A) = 1 - \text{Back}(A) \)  
- equivalently, \( \text{Lay}(A) = \sum_{i \ne A} \text{Back}(i) \)

This means a Lay is simply the inverse expression of the other Back positions.  
The ledger records all exposure in **Back** form — so when someone buys **Lay A**, it updates the Back entries for every other position.

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

### e) Receive **1 USDC**

The market maker receives 1 USDC and sends it back to the ledger.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 6       (+1)         |
| B        | 6       (+1)         |
| C        | 6       (+1)         |
| D        | 6       (+1)         |

### f) Emit **1 USDC**

THe market maker withdaws 1 USDC from the ledger and sends it somewhere.

New balance array

| Position | potential shares |
|---------:|:-----------------|
| A        | 5     (-1)           |
| B        | 5     (-1)           |
| C        | 5     (-1)           |
| D        | 5     (-1)           |

**What this shows**

- **Position tokens** redistribute potential *within* the array.  
- **USDC flows** expand or contract the array *as a whole*.  

At all times, the market maker’s potential is consistent — simply expressed as capital or as exposure.

---

## 5. Buys and Sells

### Buying Tokens

1. The **user sends USDC** to the market maker.  
2. The **market maker deposits** that USDC into the ledger.  
3. The **market maker withdraws tokens** from the ledger and transfers them to the user.  

The user ends up holding tokens, and the market maker’s balance in the ledger increases in USDC but decreases in available potential for those positions.

---

### Selling Tokens

1. The **user sends tokens** to the market maker.  
2. The **market maker deposits** those tokens into the ledger.  
3. The **market maker withdraws USDC** from the ledger and transfers it to the user.  

The user ends up holding USDC, and the market maker’s balance in the ledger decreases in USDC but regains potential exposure for those positions.
