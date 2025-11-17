---
comments: true
slug: ledger-expanding-markets  # Stable ID, e.g., for linking as /what-is-it/
title: Ledger Expanding Markets  # Optional display title
---


# Expanding Markets

## Overview

Some markets are **expanding**, meaning their set of positions can grow over time as new outcomes become relevant.  
Other markets are **fixed**, with a closed set of outcomes established at creation.

Expanding markets include one special position called **“Other.”**  
“Other” represents all possible outcomes that have not yet been listed explicitly.  
It allows the market to remain complete and internally consistent even as new positions are introduced later.

---

## The “Other” Position

In an expanding market, the initial set of positions consists of all known outcomes plus a special **non-tradable** bucket called **“Other.”**

- “Other” represents unlisted outcomes.  
- **Back Other** and **Lay Other** tokens do not exist.  
- Indirect exposure to “Other” does exist in the form of **Lay Tokens**.  
- The ledger system enforces that each Market Maker remains solvent, including holding a **non-negative position** in “Other.”  

Markets that are fixed in scope do not include “Other.”

---

## Adding New Positions

New positions are introduced by effectively **splitting** them out of “Other.”  
When a new position is created:

1. All existing positions retain their prices and balances.  
2. A new position is created, and each Market Maker receives the same number of shares in it as they held in “Other.”  

After creation, the new position behaves like any other — it can be traded, priced, and redeemed normally.

---

## Solvency

The ledger ensures that Market Makers remain solvent across **all** positions, including “Other.”

- “Other” is non-tradable but **included** in solvency calculations.  
- The system enforces that each Market Maker’s exposure to “Other” is never negative.

---

## Market Maker Behaviour

Market Makers can decide individually how to handle newly added positions:

- **Actively quote and trade** the new position.  
- **Underweight or overweight** it according to their views.  
- **Ignore it entirely** and continue operating as if it did not exist.  

A Market Maker that ignores new positions remains fully solvent.  
The system does not require participation in newly created positions.

---

## Price Continuity

The new position inherits a proportion of the original price of “Other,” while all other position prices remain unchanged.  

This ensures stable pricing and smooth behaviour when new outcomes are introduced.

---

## User Interface

Expanding markets display the **Other price** as a non-tradable informational line item.  

When a new position is added:

- “Other” decreases by the corresponding amount.  
- A **Split from Other** event is displayed for transparency.  

---

## Exposure to “Other”

- Traders’ portfolios never include “Other,” since it cannot be held or traded.  
- Market Makers can explicitly expose themselves **towards** the current “Other” (effectively *backing Other*) by selling all other positions.  
- Market Makers can explicitly expose themselves **away from** the current “Other” (effectively *laying Other*) by buying all other positions.  

---

## Rationale

Issuing tradable Back and Lay tokens for “Other” would create complex and ambiguous semantics for users.  
Instead, “Other” exists only as a non-tradable accounting reference that simplifies the system while maintaining completeness and solvency.

---

## Summary

Expanding markets support the controlled addition of new positions over time while preserving value, continuity, and solvency.  
The non-tradable “Other” position acts as a placeholder for all unlisted outcomes and provides a constant solvency reference point where Market Makers are enforced to have non-negative exposure.  

When new positions are introduced, they are carved out of “Other” without affecting existing prices or balances.  
Market Makers remain fully solvent at all times and may choose whether or not to engage with the new positions.  

This mechanism allows markets to evolve naturally as new outcomes emerge, while maintaining the same safety, accounting, and simplicity as fixed-position markets.
