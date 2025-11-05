# Solvency — Concept and Enforcement

Solvency keeps every Prediction Perps market safe and internally consistent.  
It ensures that no trade or issuance ever creates unbacked exposure,  
and that the total value circulating in a market — the fixed **1 USDC shared across all positions** — always remains whole.

---

## 1 · Solvency Without Synthetic Liquidity

In a fully funded market, solvency means that every **market maker** has enough *real USDC*  
to cover the exposure they’ve taken on.

Each market maker holds a balance inside the **Ledger**, which automatically checks and updates  
their position after every operation.  
Whenever tokens are issued, bought, sold, or redeemed, the Ledger ensures that no account  
falls below zero and that the total market value remains constant.

If a trade would require more capital than the maker currently has, the Ledger blocks it.  
If a trade simply redistributes value between positions, it’s approved.

This mechanism guarantees that:
- Every position is always backed by sufficient collateral.  
- The market cannot create or destroy value.  
- The system remains solvent by design.

---

## 2 · Solvency With Synthetic Liquidity (ISC)

When a new market launches, there may be **no real liquidity at all**.  
To allow trading and pricing from the very first block, the Ledger introduces **Internal Synthetic Collateral (ISC)** —  
a temporary internal credit line assigned to a single **Designated Market Maker (DMM)**.

ISC behaves like real USDC in solvency checks,  
allowing the market to function as if liquidity already exists.  
However, this is only safe because Prediction Perps markets **never resolve**.  
There is no end state where the market must “settle,”  
so synthetic liquidity can exist indefinitely — as long as the **redemption constraint** holds.

---

## 3 · The Redemption Constraint

The **redemption constraint** is what makes synthetic solvency possible.

It guarantees that specific combinations of tokens can *always* be redeemed for a fixed total of USDC — for example:
- **1 Back + 1 Lay = 1 USDC**  
- **A full basket of Backs = 1 USDC**

This constrains the DMM so it can only issue full sets of tokens if they are fully backed by USDC.  
At any time, a user can redeem complete token sets for 1 USDC, preserving the constant total value of the market.

---

## 4 · Additional Conditions Under ISC

Synthetic solvency adds one extra rule:

- **Profits cannot be withdrawn** while any ISC remains unrefilled.

As real USDC flows in from traders over time,  
the Ledger automatically refills the ISC balance before allowing DMM withdrawals.  
This ensures the synthetic portion of liquidity is always restored to its original depth, adding a constraint which stops DMMs syphoning off all purchases. 

---

## 5 · Further Reading

- [**Synthetic Liquidity Overview**](Accounting/SyntheticLiquidity/SyntheticOverview.md) — how ISC is introduced, used, and refilled.  
- [**Ledger Overview**](Accounting/StandardLiquidity/LedgerOverview.md) — detailed breakdown of internal solvency checks.  
- [**Zero-Sum Enforcement**](ZeroSum.md) — how constant redeemability ensures conservation of value.  

---
