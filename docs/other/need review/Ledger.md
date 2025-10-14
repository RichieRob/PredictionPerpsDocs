# Ledger Technical Details

## Overview

In traditional prediction markets like Polymarket, market makers deposit capital to mint an array of outcome shares explicitly. Creating positiosn requires splitting, merging, minting, and burning tokens. This process is gas-intensive, especially for markets with many outcomes, as operations scale with \( O(n) \), where \( n \) is the number of outcomes.

The **ledger** takes a different approach, tracking **virtual outcome shares** internally without minting physical token arrays. This allows the Market Maker to have full flexibility in buying and selling positions, without the need to split and merge positions.

- Deposits and redemptions are \( O(1) \), minimizing gas costs.
- Outcome shares are virtualized, and tokens are minted **only on demand**.
- No splitting or merging is required.

This means the central system is just **adding up numbers** and lazily minting tokens on demand.

The Ledger is agnostic about pricing and all pricing is down to Market Makers.

---

## Ledger Accounting

The ledger tracks **virtual shares** for each Market Maker (MM), ensuring each market maker keeps a non-negative balance per outcome (\( H_k \geq 0 \)).

### Key Components

#### Uniform Credit (v)
- `int256 v`: Collateral in vUSDC, equivalent to holding \( v \) **virtual shares for every outcome**.
- Think of this as a **balanced set of outcome shares**.

#### Tilt Mapping
- `mapping(uint256 => int128) tilt`: Adjusts outcome shares per ID (\( k \)).
- Signed, so tilts can be positive or negative.

#### Effective Virtual Shares

\[
H_k = v + \text{tilt}[k]
\]

Represents the **effective virtual share balance** for outcome \( k \).

#### Restraint
Each market maker must satisfy:

\[
H_k \geq 0 \quad \text{for all outcomes } k
\]

---

# Relationship Between Back and Lay

The core principle governing Back and Lay tokens is explicitly defined as:

\[
\text{Back}(A) + \text{Lay}(A) = 1 \, \text{vUSDC}
\]

This ensures that the sum of a Back token and its corresponding Lay token always equals 1 vUSDC, maintaining balance in the market.

- A **Back** token represents direct exposure to a specific outcome, denoted as \(\text{Back}(A)\).
- A **Lay** token is its complement, explicitly defined by the equation:

\[
\text{Lay}(A) = 1 \, \text{vUSDC} - \text{Back}(A)
\]



## Withdrawing 1 Lay A
When the Market Maker (MM) withdraws **1 Lay A** from the Ledger :

Ledger Balance:

- **down 1 vUSDC**
- **up 1 A**

## Depositing 1 Lay A

Conversely, when the MM deposits **1 Lay A** into the Ledger:

Ledger Balance:

- **up 1 vUSDC**
- **down 1 Back A**

## Operation Semantics (Ledger Updates)

| Operation | Token Flow | v update | tilt<sub>k</sub> update | Notes |
|-----------|------------|----------|-------------------------|-------|
| **Deposit vUSDC** | MM -> Ledger: u vUSDC | v += u | — | |
| **Withdraw vUSDC** | Ledger -> MM: u vUSDC | v -= u | — | u <= min<sub>k</sub> H<sub>k</sub>. |
| **Mint Back k** | Ledger -> MM: q Back<sub>k</sub> | — | tilt<sub>k</sub> -= q | |
| **Receive Back k** | MM -> Ledger: q Back<sub>k</sub> | — | tilt<sub>k</sub> += q | |
| **Mint Lay k** | Ledger -> MM: q Lay<sub>k</sub> | v -= q | tilt<sub>k</sub> += q | Because Lay = 1 - Back |
| **Receive Lay k** | MM -> Ledger: q Lay<sub>k</sub> | v += q | tilt<sub>k</sub> -= q | Because Lay = 1 - Back |

---

## Example Trades

Assume a market with positions A, B, C.

### Initial State (Empty Ledger)

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Ledger starts empty.

---

### 1) Balanced Deposit (100 vUSDC)

Operation: MM deposits 100 vUSDC → `v += 100`.

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 100 | 0 | 0 | 0 | 100 | 100 | 100 |

---

### 2) Issue Back A (40 Back A for 20 vUSDC)

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 120 | -40 | 0 | 0 | 80 | 120 | 120 |

CMM mints 40 Back A and gives them to MM. Ledger rebalances.

---

### 3) User Sells 50 Back B (MM pays 10 vUSDC)

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 110 | -40 | 50 | 0 | 70 | 160 | 110 |

CMM burns 50 Back B. MM receives 10 vUSDC.

---

### 4) User Buys 9 Lay A (MM pays 10 vUSDC)

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 111 | -31 | 50 | 0 | 80 | 161 | 111 |

- `v = v + 10 - 9` (collateral added, but liability for 9 Lay A).
- `tilt<sub>A</sub> = tilt<sub>A</sub> + 9`.

CMM mints 9 Lay A and sends them to MM.

---

### 5) User Sells 2 Lay C (MM pays 1 vUSDC)

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 112 | -31 | 50 | -2 | 81 | 162 | 110 |

CMM burns 2 Lay C and gives 1 vUSDC to MM.

---

### 6) Balanced Redemption

- Max redeemable = **min<sub>k</sub> H<sub>k</sub>**.
- Here, \( \min_k H_k = 81 \).
- MM withdraws 81 vUSDC.

| v | tilt<sub>A</sub> | tilt<sub>B</sub> | tilt<sub>C</sub> | H<sub>A</sub> | H<sub>B</sub> | H<sub>C</sub> |
|---|------------------|------------------|------------------|---------------|---------------|---------------|
| 31 | -31 | 50 | -2 | 0 | 81 | 29 |

CMM sends 81 vUSDC to MM.
The MM still has B and C tokens they can **sell or they can deposit additional tokens** to recover more USDC.
This ensures the ledger never allows full withdrawal unless all tilts are balanced.

---

## 7) Multiple-Outcome Markets

So far, we have only looked at markets with **one winner**.  
For example, an election: one candidate wins, all others lose.  
In that case, solvency is simple — each effective balance \( H_k = v + \text{tilt}[k] \) must be non-negative.  

However we can equally apply this to events with multiple outcomes. 

A good example is the **English Premier League relegation market**, where exactly **three clubs** go down together.  

---

### Step 1. What changes with multiple winners?

If three teams are relegated, the market maker must be able to pay all three at once.  
That means we can’t just check a single team’s balance. We need to look at the **three weakest balances** together.

---

### Step 2. Headroom per team

As before, for each outcome \( k \):

\[
H_k = v + \text{tilt}[k]
\]

- \( v \) is the uniform budget in vUSDC.  
- \( \text{tilt}[k] \) tracks how much Back or Lay exposure you’ve taken on outcome \( k \).  
- \( H_k \) is the “headroom” — how much slack you have on that outcome.  

Every team must still satisfy \( H_k \ge 0 \).  
But with multiple winners, that’s not enough.

---

### Step 3. Liability if three teams win

Suppose \( v = 10 \).  
Balances are:

- \( H_A = 7 \)  
- \( H_B = 6 \)  
- \( H_C = 9 \)  
- \( H_D = 12 \)

The three smallest are \( h_1 = 6, h_2 = 7, h_3 = 9 \).

If A, B, and C all get relegated:  
- Liability for A = \( v - H_A = 10 - 7 = 3 \)  
- Liability for B = \( 10 - 6 = 4 \)  
- Liability for C = \( 10 - 9 = 1 \)  
- Total liability = \( 3 + 4 + 1 = 8 \)

Budget \( v = 10 \).  
Since \( 8 \le 10 \), this is safe.

---

### Step 4. General formula

For \( m \) winners:  
- Worst case is the \( m \) smallest balances \( h_1, h_2, \dots, h_m \).  
- Liability = \( \sum_{i=1}^m (v - h_i) = m v - (h_1 + h_2 + \dots + h_m) \).  
- This must be ≤ budget \( v \).  

So the condition is:

\[
h_1 + h_2 + \dots + h_m \;\;\ge\;\; (m-1) v
\]

---

### Step 5. Special cases

- \( m = 1 \): \( h_1 \ge 0 \) (the basic non-negative rule).  
- \( m = 2 \): \( h_1 + h_2 \ge v \).  
- \( m = 3 \): \( h_1 + h_2 + h_3 \ge 2v \).  
- \( m = 4 \): \( h_1 + h_2 + h_3 + h_4 \ge 3v \).  

And so on.

---

### Step 6. Implementation

To enforce this in practice:  
- Track each \( H_k \) as usual.  
- Keep a cache of the smallest \( m+1 \) balances.  
- After any deposit, withdrawal, or mint/burn, update the changed \( H_k \).  
- Check the condition \( h_1 + \dots + h_m \ge (m-1) v \).  

This way the ledger stays efficient — only one balance changes per operation —  
but it now works for **multi-winner markets** like EPL relegation.
