---
comments: true
---


# Solvency — Concept and Enforcement

Solvency keeps every Prediction Perps market safe and internally consistent.  
It ensures that no trade, issuance, or withdrawal ever creates unbacked exposure,  
and that the total value circulating in a market — the fixed **1 USDC shared across all positions** — always remains whole.

---

## 1 · Solvency Without Synthetic Liquidity

In a fully funded market, solvency means that every **market maker (MM)**  
always has enough *real USDC* to cover their active exposure.

Each market maker holds a balance inside the **Ledger**,  
which continuously checks their position after every trade or redemption.  
Whenever tokens are issued, bought, sold, or redeemed,  
the Ledger ensures that no account falls below zero and that the total market value remains constant.

If a trade would require more capital than the maker currently has, the Ledger blocks it.  
If a trade simply redistributes value between positions, it is approved.

This mechanism guarantees that:
- Every position is always backed by sufficient collateral.  
- The market cannot create or destroy value.  
- The system remains solvent by design.

---

## 2 · Solvency With Synthetic Liquidity (ISC)

When a new market launches, there may be **no real liquidity at all**.  
To enable immediate pricing and trading, the Ledger introduces **Internal Synthetic Collateral (ISC)** —  
a temporary internal credit line assigned to a single **Designated Market Maker (DMM)**.

ISC behaves like real USDC during solvency checks,  
allowing the market to function as if liquidity already exists.  

This design is only safe because Prediction Perps markets **never resolve** —  
there is no final “payout” moment where all exposure must settle in cash.  
Synthetic liquidity can therefore exist indefinitely,  
so long as the **redemption constraint** is continuously maintained.

---

## 3 · The Redemption Constraint

The **redemption constraint** is what makes synthetic solvency safe.

It guarantees that certain combinations of tokens can *always* be redeemed  
for a fixed total of 1 USDC, ensuring that synthetic liquidity never breaks the constant-sum rule.

For example:
- **1 Back + 1 Lay = 1 USDC**  
- **A full basket of all Backs = 1 USDC**

This ensures the DMM can only issue positions that remain redeemable  
within the system’s total collateral.  
At any time, a user can redeem full sets of tokens for 1 USDC,  
preserving the fixed total value of the market.

---

## 4 · Withdrawals and Profit Realisation

### Market Makers (MMs)
A normal **market maker** can withdraw *only* the portion of their real collateral  
not currently required to maintain solvency.

Before any withdrawal, the Ledger re-evaluates:

\[
\min_k(\text{freeCollateral} + \text{USDCSpent} + \text{layOffset} + \text{tilt}[k]) \ge 0
\]

If withdrawing would cause this expression to fall below zero,  
the transaction reverts — preventing the maker from over-withdrawing and breaking solvency.

### Designated Market Makers (DMMs) under ISC
For a DMM operating with synthetic liquidity, a single additional condition applies:

- **Profit Realisation Only When Fully Covered** —  
  The DMM can realise profits (negative `USDCSpent`) only after all synthetic exposure  
  has been fully replaced with real USDC and the market remains redeemable.

This ensures that ISC-backed liquidity cannot leak out as profit  
until every unit of synthetic credit has been refilled by real capital.

---

## 5 · Why This Works

The combination of:
- **Heap-based tilt tracking** (instant solvency checks)  
- **Constant-sum accounting** (zero-sum enforcement)  
- **Synthetic refill logic** (ISC redemption discipline)

creates a system that cannot drift into insolvency, even under heavy trading load.  

Every operation — from issuing a Back token to withdrawing profits —  
must pass the same invariant tests before execution.

---

## 6 · Further Reading

- [**Synthetic Liquidity Overview**](./Accounting/SyntheticLiquidity/SyntheticOverview.md) — how ISC is introduced, used, and refilled.  
- [**Ledger Overview**](./Accounting/StandardLiquidity/LedgerOverview.md) — full breakdown of the accounting model.  
- [**Solvency Accounting**](./SolvencyAccounting.md) — detailed algorithmic description of how solvency checks are computed.  
- [**Zero-Sum Enforcement**](ZeroSum.md) — how constant redeemability ensures conservation of value.  

---
    