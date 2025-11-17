---
comments: true
slug: solvency-accounting  # Stable ID, e.g., for linking as /what-is-it/
title: Solvency Accounting  # Optional display title
---

# Solvency Accounting

This document explains how solvency is enforced algorithmically inside the **Ledger**,  
including how `minTilt` and `maxTilt` are tracked, how the heap system works,  
and how solvency checks differ when **Synthetic Liquidity (ISC)** is active.

It assumes familiarity with:

- [**Ledger Overview**](../StandardLiquidity/LedgerOverview.md)  
- [**Heap Logic**](../StandardLiquidity/HeapLogic.md)  
- [**Synthetic Liquidity Accounting**](../SyntheticLiquidity/SyntheticAccounting.md)

---

## 1 · What Solvency Means in Accounting Terms

At any time, for a given market maker \( \text{mmId} \) and market \( \text{marketId} \):

\[
H_k = \text{freeCollateral} + \text{USDCSpent} + \text{layOffset} + \text{tilt}[k]
\]

Each \( H_k \) represents the *effective collateral* behind position \( k \).

To stay solvent:
\[
\min_k(H_k) \ge 0
\]
This ensures that every position, even the most over-issued one, remains fully backed by real or synthetic capital.

The **Ledger** enforces this condition after every operation — mint, burn, buy, sell, redeem, or withdrawal.

---

## 2 · How Solvency Is Checked

Solvency enforcement runs through two core checks:

| Check | Description |
|--------|--------------|
| **Minimum Tilt Check** | Finds the smallest tilt (worst exposure) across all positions. The heap structure tracks this value in O(1). |
| **Redemption Check (only with ISC)** | Ensures the market has enough real capital to redeem all *complete sets* of tokens (1 Back + 1 Lay = 1 USDC). |

Together these ensure both per-position and aggregate solvency.

---

## 3 · The Heap System

See full details in [**Heap Logic**](../StandardLiquidity/HeapLogic.md).

The heap system allows the Ledger to efficiently query and update the **minimum tilt** (and when ISC is active, also the **maximum tilt**) across `n` positions.

### Without ISC

Only the **minimum tilt** matters.  
Solvency is determined by:

\[
\text{minShares} = \text{USDCSpent} + \text{layOffset} + \text{minTilt}
\]

If `minShares` falls below zero, the Ledger allocates real USDC from `freeCollateral` to `USDCSpent` until it reaches zero again.  
If `minShares` rises above zero, it deallocates real USDC back to `freeCollateral`.

→ The heap provides `minTilt` instantly, ensuring solvency enforcement is **O(1)** per operation.

---

### With ISC Enabled

When **Synthetic Liquidity** is active for a **Designated Market Maker (DMM)**,  
the Ledger performs two heap lookups:

- `minTilt` → for solvency (as usual)  
- `maxTilt` → for redemption constraints

The calculations become:

\[
\text{realminShares} = \text{USDCSpent} + \text{layOffset} + \text{minTilt}
\]

\[
\text{effectiveminShares} = \text{realminShares} + \text{ISC}
\]

\[
\text{redeemableSets} = -\text{layOffset} - \text{maxTilt}
\]

Rules enforced:

- If `effective_minShares < 0`: allocate real from `freeCollateral → USDCSpent`.  
- If `USDCSpent < redeemableSets`: allocate real to ensure redeemability.  
- When deallocating, cap by these same constraints.

Thus, solvency is guarded by **minTilt**, and redeemability by **maxTilt**,  
each efficiently maintained in its own heap.

---

## 4 · Withdrawal Checks

Before any withdrawal request, the Ledger performs the same solvency checks  
as if executing a trade — ensuring that removing capital never breaks coverage.

| Actor | Condition | Effect |
|--------|------------|--------|
| **Market Maker (MM)** | `minShares ≥ 0` after withdrawal | Prevents removing collateral needed to back active exposure. |
| **Designated Market Maker (DMM)** | `effective_minShares ≥ 0` **and** `USDCSpent ≥ redeemableSets` | Ensures synthetic exposure is still covered and redeemability remains intact. |

Additionally, DMM withdrawals are subject to the rule:  
**profits (negative `USDCSpent`) can only be realised once ISC = 0**  
— meaning all synthetic credit has been refilled by real inflows.

---

## 5 · Dual-Heap Implementation

When ISC is active, the Ledger maintains two parallel heaps per market:

| Heap | Purpose | Tracked Value | Direction |
|------|----------|---------------|------------|
| **Min-Heap** | Solvency | `minTilt` | smallest tilt |
| **Max-Heap** | Redemption | `maxTilt` | largest tilt |

Each is updated whenever a position’s `tilt[k]` changes (Back or Lay issue/receive).  
Both heaps operate in **O(log₄(n/16))** time for updates and **O(1)** for lookup,  
reusing the same block structure (`B = 16`, `d = 4`) described in [Heap Logic](../StandardLiquidity/HeapLogic.md).

---

## 6 · Summary

| Mode | Heaps Used | Constraints Enforced | Description |
|------|-------------|----------------------|--------------|
| **Without ISC** | `minTilt` only | `minShares ≥ 0` | Real-collateral solvency only |
| **With ISC** | `minTilt` + `maxTilt` | `effective_minShares ≥ 0` and `USDCSpent ≥ redeemableSets` (+ ISC refill before profit) | Synthetic solvency + redemption constraint |

This dual-heap design allows real-time solvency checks at near-constant gas cost,  
even in markets with thousands of positions.

---

## 7 · Further Reading

- [**Heap Logic**](./HeapLogic.md) — full explanation of the 4-ary min/max heap implementation.  
- [**Synthetic Liquidity Accounting**](./Accounting/SyntheticLiquidity/SyntheticAccounting.md) — how ISC modifies solvency.  
- [**Ledger Overview**](./Accounting/StandardLiquidity/LedgerOverview.md) — higher-level context of market-maker accounting.  
- [**Solvency — Concept and Enforcement**](./Solvency.md) — conceptual overview and rationale for solvency rules.  

---
