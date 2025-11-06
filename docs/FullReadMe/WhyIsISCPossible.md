---

## Applicability and the Redemption Constraint

### Why Synthetic Liquidity Cannot Be Used in Resolving Markets
In a **resolving** market, outstanding claims must be paid out to a single winning outcome in **real collateral**.  
**ISC (Internal Synthetic Collateral)** is not real funds; it is only a virtual depth parameter for pricing.  
If ISC were present at resolution, part of the apparent liquidity would lack USDC to settle, creating a shortfall.  
Therefore **ISC is incompatible with resolving markets**.

---

### Why It Works for Non-Resolving Markets
Prediction Perps markets are **non-resolving** and **zero-sum**: value continually redistributes among positions, and the market never pays an external settlement.  
ISC only shapes the **price response** (depth) from block one; all trades still move **real USDC** between users.  
Because there is no terminal payout, ISC never needs to “fund” a resolution—it merely affects curvature.

---

### The Redemption Constraint (Full Baskets / Unified Shares)
Redemption is defined over **full baskets** (a.k.a. **unified shares**)—the canonical bundle of positions that, when held together, is redeemable for the fixed unit (typically **1 USDC**).  
Individual legs are **not** directly redeemable; they must first be combined (via trades) into full baskets.

The protocol enforces a strict lower-bound invariant:

> **At all times, the system holds at least enough real collateral to redeem every outstanding full basket at the fixed unit value.**  
> Formally, `RealCollateral >= (OutstandingFullBaskets * UnitRedeemable)`, with `UnitRedeemable = 1 USDC`.  
> **ISC never counts as real collateral.**

Implications:
- The constraint is a **lower bound**: in practice there is usually **more** real collateral than the minimum (e.g., idle cash from trades, spread/fee accrual, etc.).  
- Because redemption acts only on **full baskets**, the invariant guarantees that simultaneous redemption of all **baskets** is solvent, regardless of how positions are distributed across outcomes.  
- ISC cannot create unbacked claims: it affects *pricing curvature*, not the *redeemable supply*.

In short: **ISC is safe in non-resolving markets because redemption is defined on full baskets and the system always holds at least the real collateral required to redeem them.**
