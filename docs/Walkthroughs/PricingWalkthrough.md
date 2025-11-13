---
title: Pricing Walkthrough — Fruit Market
description: Step‑by‑step, numbers‑driven walkthrough showing how prices move in practice for the Fruit Market initialized in MarketInitialisation.md, using 10,000 USDC of synthetic liquidity.
---

# Pricing Walkthrough — Fruit Market

> **Audience**: traders, reviewers, and devs who want to *see* prices move in practice.  
> **Pre‑reqs**: skim these first:  
> • [**Market Initialisation**](../Flows/MarketInitialisation.md) — the fruit market we’ll use here.  
> • [**LMSR Purchase Flow**](../Flows/PurchaseToken/PurchaseFlowLMSR.md) — where pricing is applied.  
> • [**Ledger Purchase Flow**](../Flows/PurchaseToken/PurchaseFlowLedger.md) — how USDC/ISC moves and minting happens.  
> • [**Synthetic Liquidity — Overview**](../FullReadMe/Accounting/SyntheticLiquidity/SyntheticOverview.md).

---

## 1 · Scenario Setup (from *MarketInitialisation.md*)

- **Market**: *Fruit* (marketId = `0`)
- **Positions (Back tokens)**: `Apple (APL)`, `Banana (BAN)`, `Cucumber (CUC)`, `Dragon Fruit (DRF)`
- **Initial target weights** (Back):  
  Apple **0.40**, Banana **0.10**, Cucumber **0.30**, Dragon Fruit **0.10**  
  *(Remaining 0.10 sits in an internal reserve/“Other”, not listed.)*
- **Synthetic Liquidity (ISC depth)**: **10,000 USDC** for the designated MM on this market.
- **AMM**: LMSR with O(1) updates (global/local decomposition). See [AMM notes](../FullReadMe/AMM.md).

> **Why these numbers?** This is exactly the setup used in the initialisation walkthrough: we start with 3 fruits (0.40/0.10/0.30 + 0.20 reserve), then split the reserve by +0.10 to create **Dragon Fruit**, leaving **0.10** in reserve.

---

## 2 · How Pricing Works (at a glance)

We use a standard LMSR cost function:

- **Cost**: \( C(\mathbf{q}) = b \cdot \ln\left(\sum_i e^{q_i/b}\right) \)  
- **Instant price** for outcome *i*: \( p_i = \frac{e^{q_i/b}}{\sum_j e^{q_j/b}} \)  
- **Spend S on outcome i** → find \(\Delta q_i\) such that \( C(q_i + \Delta q_i) - C(q) = S \).

**Depth parameter `b`.** In our deployment, the *effective* depth at genesis is set by synthetic liquidity (ISC). As a rule of thumb, start with **b ≈ 10,000 USDC** for this market, matching the seeded ISC depth. (Exact mapping is implementation‑specific; see [Synthetic Principles](../FullReadMe/Accounting/SyntheticLiquidity/SyntheticPrinciples.md).)

> **Note.** We initialize \(\mathbf{q}\) so that initial prices match the target weights above. This makes the very first quoted prices equal to those weights.

---

## 3 · Walkthrough — A Short Trading Session

Below we run a sequence of realistic trades and show how prices move. Each step lists **before/after** price vectors and the intuition.

### Legend

- **State**: \(\mathbf{p} = [p_{APL}, p_{BAN}, p_{CUC}, p_{DRF}]\) — listed Back prices (they do **not** sum to 1.0 because *Other* is off‑market).  
- **Call**: The on‑chain function used.  
- **Effect**: Intuition using the O(1) LMSR global/local shift notation.

---

### Trade 1 — Buy Back **Apple** with 1,000 USDC

**Before**: `p ≈ [0.40, 0.10, 0.30, 0.10]`  
**Call**:
```solidity
LMSRMarketMaker.buyForUSDC(
  /* marketId */      0,
  /* positionId */    APL_ID,
  /* isBack */        true,
  /* usdcIn */        1_000e6,
  /* tMax */          0,
  /* minTokensOut */  X,
  /* usePermit2 */    true,
  /* permitBlob */    PERMIT2_SINGLE
);
```
**Effect (intuition)**: raises *Apple*’s log‑quantity \(q_{APL}\) by \(\Delta q\). Prices tilt toward Apple; others drop slightly.  
**After**: `p ≈ [0.44, 0.095, 0.285, 0.095]` *(illustrative)*

---

### Trade 2 — Buy Back **Cucumber** with 2,500 USDC

**Before**: `p ≈ [0.44, 0.095, 0.285, 0.095]`  
**Call**: `buyForUSDC(0, CUC_ID, true, 2_500e6, ...)`  
**Effect**: strong shift toward *Cucumber*; Apple relaxes.  
**After**: `p ≈ [0.40, 0.090, 0.33, 0.088]` *(illustrative)*

---

### Trade 3 — Buy **Lay** on **Banana** with 1,200 USDC

**Before**: `p ≈ [0.40, 0.090, 0.33, 0.088]`  
**Call**: `buyForUSDC(0, BAN_ID, /* isBack = */ false, 1_200e6, ...)`  
**Effect**: Lay(Banana) increases, which (dually) lowers Back(Banana) price and shifts some weight to others.  
**After**: `p ≈ [0.41, 0.080, 0.335, 0.085]` *(illustrative)*

---

### Trade 4 — Buy Back **Dragon Fruit** with 800 USDC

**Before**: `p ≈ [0.41, 0.080, 0.335, 0.085]`  
**Call**: `buyForUSDC(0, DRF_ID, true, 800e6, ...)`  
**Effect**: nudges DRF upward from a thin base; mild pull from others.  
**After**: `p ≈ [0.405, 0.078, 0.328, 0.095]` *(illustrative)*

---

### Trade 5 — Buy **Lay** on **Apple** with 3,000 USDC

**Before**: `p ≈ [0.405, 0.078, 0.328, 0.095]`  
**Call**: `buyForUSDC(0, APL_ID, /* isBack = */ false, 3_000e6, ...)`  
**Effect**: pushes back against Apple’s dominance; redistributes mass to others.  
**After**: `p ≈ [0.36, 0.085, 0.345, 0.095]` *(illustrative)*

---

## 4 · Reading the Moves

- **Depth matters.** With **b ≈ 10k**, 1–3k USDC trades create *noticeable* but not extreme moves. Larger `b` ⇒ smoother prices.  
- **Listed vs Reserve.** Prices shown are for **listed** outcomes. The hidden “Other” absorbs some mass, so listed prices needn’t sum to 1.  
- **Back vs Lay symmetry.** Back buys add to an outcome’s log‑quantity; Lay buys reduce it (and vice‑versa for sells), with global shifts maintaining normalization.

> For the exact global/local shift logic, see the O(1) notes in [**AMM**](../FullReadMe/AMM.md) and the implementation in `LMSRMarketMaker` (plus helpers).

---

## 5 · Verifying On‑Chain (dev checklist)

1. **Quote first** (slippage):  
   ```solidity
   (uint256 tOut) = amm.quoteBuyForUSDC(0, POS_ID, isBack, usdcIn, 0);
   ```
2. **Submit trade** with `minTokensOut`.  
3. **Inspect events**: pre/post TWAP, quantities, and price emissions.  
4. **Ledger invariants** hold: balances adjust; mint ERC‑1155 (Back/Lay) to the trader; solvency checks pass.  
   See: [Ledger Purchase Flow](../Flows/PurchaseToken/PurchaseFlowLedger.md).

---

## 6 · Appendix — Reproducible Math

If you want the **exact** numbers for the sequence above:

- Use **b = 10,000** (or your market’s configured depth),  
- Initialize \(q\) so that \(p = [0.40, 0.10, 0.30, 0.10]\),  
- For each trade, solve \( C(q + \Delta q) - C(q) = S \) for the target outcome and compute the new \(p\).

> We keep this walkthrough human‑readable. For ground‑truth, run the same trades against the contract or a local simulator and paste the price vectors into the “After” slots above.

---

## READ MORE

- [Market Initialisation](../Flows/MarketInitialisation.md)  
- [Purchase Flow — Overview](../Flows/PurchaseToken/PurchaseFlowOverview.md)  
- [Purchase Flow — LMSR](../Flows/PurchaseToken/PurchaseFlowLMSR.md)  
- [Purchase Flow — Ledger](../Flows/PurchaseToken/PurchaseFlowLedger.md)  
- [Synthetic Liquidity — Overview](../FullReadMe/Accounting/SyntheticLiquidity/SyntheticOverview.md)  
- [Ledger Accounting (standard)](../FullReadMe/Accounting/StandardLiquidity/LedgerAccounting.md)
