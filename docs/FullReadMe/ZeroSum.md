# Zero-Sum

Prediction Perps markets are **zero-sum by design** — the total value across all [**Positions**](../Glossary.md#position) in a [**Market**](../Glossary.md#market) is fixed and can never be created or destroyed.  
This balance is maintained through **structural redemption rules** that ensure all Positions share a common pool of collateral (typically **1 USDC**).

---

## Binary Example — The Intuitive Case

Let’s start with a simple **binary market** — “YES” vs “NO”:

- Begin with **1 USDC**.  
- That 1 USDC can be **split** into one **YES** and one **NO** token.  
- At any time, **YES + NO → 1 USDC** through redemption.

Because this rule always holds, the prices stay linked:  
if **YES = 0.6**, then **NO = 0.4**, and together they total **1 USDC**.

> The zero-sum rule means: when one side gains, the other loses — but the total value never changes.

---

## Beyond Binary — The n-Dimensional Case

Traditional prediction platforms (like Polymarket) create multi-outcome events as **arrays of binary markets** sharing the same resolution:

| Outcome | Binary Pair |
|----------|-------------|
| Liverpool | YES / NO |
| Everton | YES / NO |
| Manchester United | YES / NO |

At settlement, only one “YES” wins while all others go to zero.  
The linkage between prices comes from that **shared external resolution event**.  

But in a **perpetual, non-resolving** market, there’s no such event — so the binary pairs would drift independently unless something else enforces balance.

---

## Structural Zero-Sum — The Prediction Perps Model

Prediction Perps removes the dependency on resolution events entirely.  
Instead of external settlement, it maintains a **internal linkage** between all [**Positions**](../Glossary.md#position) in a [**Market**](../Glossary.md#market).

- The Market enforces the invariant:  
  > **Σ (Positions) = 1 USDC**

This invariant keeps the total value of the Market constant at all times — value can only move *between* Positions not out of the Market.

---

## Enforcement of Structural Zero-Sum

The enforcement of the structural Zero-Sum mechanism is through **[Issuance](../Glossary.md#issuance)** and  **[Redemption](../Glossary.md#redemption)**

### Issuance

Starting with **1 USDC** can **[Issue](../Glossary.md#issuance)**  a **[Full Basket](../Glossary.md#full-basket)** of shares in a [**Market**](../Glossary.md#market) :

> 1 USDC → { Backₐ, Back_b, … Backₙ } = Full Basket
or
> 1 USDC → { Backₐ, Lay_a } = Full Basket
etc

Each Full Basket represents **unity exposure** — +1 to every [**Position**](../Glossary.md#position) in the [**Market**](../Glossary.md#market).  

---

### Redemption

Similary at any time, that Full Basket can be **[Redeemed](../Glossary.md#operations)** back into **1 USDC**:

> { Backₐ, Back_b, … Backₙ } → 1 USDC
or
> { Backₐ, Lay_a } → 1 USDC
etc

Issuance and Redemption are exact opposites.

---

### Structural Redemption Rules

So for each market.

- A **Back** and **Lay** token for the same [**Position**](../Glossary.md#position) always **redeem → 1 USDC**.  
- A Full set of back tokens **redeems → 1 USDC**.  
- A Full set of lay tokens **redeems → (n − 1) USDC**.

---

## Summary

| Concept | Description |
|----------|-------------|
| **Binary zero-sum** | YES + NO = 1 USDC |
| **n-Dimensional zero-sum** | Σ (n Positions) = 1 |
| **Collateral invariance** | Value moves between Positions |
| **Redemption identity** | Full Basket = 1 USDC |

---

## Further Reading

- For all defined terms see [**Glossary**](../Glossary.md).  
- For accounting and solvency details see [**Ledger Overview**](Accounting/StandardLiquidity/LedgerOverview.md).  
