# Zero-Sum

Prediction Perps markets are **zero-sum by design** — the total value across all positions in a market is constant and cannot be created or destroyed.  
This relationship is maintained mathematically through **redemption rules**, which define how tokens can be combined or split back into a fixed total (usually **1 USDC**).

---

## Binary Example — The Intuitive Case

In a simple **binary market** (like Polymarket):

- Creation of binary shares
- Start with **1 USDC**.  
- That 1 USDC can be **split** into one **YES** and one **NO** token.  
- At any time, one **YES** + one **NO** can be **redeemed** back for 1 USDC.  

Because of this rule, the prices are always linked:  
if **YES = 0.6**, then **NO = 0.4**, and their combined value remains 1 USDC.

> The zero-sum rule means: the total value of all positions is fixed; when one increases, the others decrease proportionally.

---

## Beyond Binary — The n-Dimensional Case

Polymarket multi-position markets (for example, *Winner of the Premier League*) are currently built as **arrays of binary markets** that share a common resolution event:

| Market | YES / NO Pair |
|---------|---------------|
| Liverpool | YES / NO |
| Everton | YES / NO |
| Manchester United | YES / NO |

Each binary pair resolves from the same outcome, with only one “YES” winning at settlement.  
It is this resolution event which creates implicit linking between the array of binary markets.
However, for perpetual markets without a resolution event, these binary markets would float independently and there would be no linkage between prices.

Prediction Perps removes the external dependency entirely.  
It extends the **zero-sum constraint** to an **n-dimensional system**, where all positions coexist within one shared accounting environment.  
Here, the link between all positions is structural within the ledger — not event-based.

### n-Dimensional Market Example

- **Creation of n shares**
  - Start with **1 USDC**.
  - That 1 USDC can be **split** into *n* positions — **A, B, C … N**.
  - At any time, a **complete basket** of positions *(A → N)* can be **redeemed** for **1 USDC**.

Because of this rule, prices are always linked:

> If **A = 0.3**, then the **sum of all other positions (B → N)** must equal **0.7**.

This structural linkage keeps the total value constant across every position in the market —  
no external event or oracle is required.

---

## Structural Redemptions

Within each Prediction Perps market:

- A **Back** and **Lay** for the same position always redeem to **1 USDC**.  
- A **full basket of Back tokens** (one per position) also redeems to **1 USDC**.  
- A **full basket of Lay tokens** (one per position) redeems to **(n − 1) USDC**.

These redemption identities define the internal zero-sum structure.  
They ensure that the prices in the market stay intrinsically linked.
---

## Further Reading

For a deeper look at how these redemption and balance relationships are implemented within the ledger, start with [**Ledger Overview**](./Accounting/StandardLiquidity/LedgerOverview.md).