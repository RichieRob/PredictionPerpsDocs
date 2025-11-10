---
comments: true
---

#Prediction Perps Introduction

## What Is It?

Prediction Perps creates tradable leaderboards, where positions battle for dominance in resolutionless prediction markets with prices dynamically shifting as traders back their picks.
 
something like this
Each leaderboard tracks a single theme: it might show which crypto influencer holds the most attention, which footballer is most in form, or which technology trend is gaining momentum. Inside that leaderboard, every position represents one competitor.  
When traders buy a position, its share of the total increases while the others decrease.  
The overall value always remains the same — it’s simply redistributed as sentiment changes.

Think of it as a live ranking that reacts to the crowd in real time. Prices move as traders express conviction or respond to events, keeping the leaderboard continuously updated.

Prediction Perps can host a **series of these leaderboards**, each with its own set of positions and its own internal economy — but all following the same rule: a fixed total of **1 USDC** constantly re-divided among participants.

These markets never close or resolve. They run indefinitely, showing how belief, performance, or attention shifts over time. And they can even launch with **no initial liquidity** — the system provides internal liquidity so trading can begin instantly.


---

## What Is It For?

Prediction Perps can be used to create markets that measure attention, performance, or influence — anywhere outcomes compete for a shared spotlight.

Each market becomes its own living leaderboard, showing how sentiment shifts over time.

| Category | Example Market | What It Tracks |
|-----------|----------------|----------------|
| **Crypto** | Biggest Market Influencer | Which figure is driving the most attention right now |
| **Politics** | Most Influential Leader Today | Whose global profile or approval is rising fastest |
| **Football** | Best Footballer | Which player is seen as most in form this season |
| **NFL** | Most Valuable Player | Who is viewed as the top performer week by week |

These markets can be used for **sentiment tracking**, **continuous prediction**, or **dynamic re-weighting** — allowing traders, analysts, and fans to see, in real time, how belief and attention flow between competitors.

## Example Market — Crypto Influence

Imagine a live market tracking the relative influence of well-known crypto figures.  
Each position represents one account — for instance:

| Position | Example Account |
|-----------|----------------|
| A | @elonmusk |
| B | @cz_binance |
| C | @saylor |
| D | @vitalikbuterin |
| ... | ... |
| Z | @naval |

Together these positions form a single system that always sums to **1 USDC**, no matter how many there are.  
At the start, the market might value them equally ≈ 0.038 USDC:

| Account | Price (USDC) | Share of total |
|----------|---------------|----------------|
| @elonmusk | 0.038 | 3.8 % |
| @cz_binance | 0.038 | 3.8 % |
| @saylor | 0.038 | 3.8 % |
| ... | ... | ... |
| @naval | 0.038 | 3.8 % |
| **Total** | **1.00** | **100 %** |

Now suppose @elonmusk dominates the headlines. Traders buy his token, expecting his influence to rise. His price increases, and every other position adjusts automatically so that the total value still equals 1 USDC:

| Account | New Price (USDC) | Share of total |
|----------|------------------|----------------|
| @elonmusk | 0.10 | 10 % |
| @cz_binance | 0.037 | 3.7 % |
| @saylor | 0.037 | 3.7 % |
| ... | ... | ... |
| @naval | 0.035 | 3.5 % |
| **Total** | **1.00** | **100 %** |

Just like Polymarket, traders can **buy or sell positions at the current price** to enter or exit the market at any time. The difference is that this market **never resolves** — prices continue updating as sentiment shifts.  

Even with dozens (or hundreds) of positions, the same rule applies:  
the total market value always equals 1 USDC, and every movement in one position is offset across all others. The result is leaderboards with a an plethora of positions, continuously redistributing a single shared unit of value among many participants.

---

## Key Properties

- 🕒 **Perpetual** — markets never close or resolve; they run indefinitely.  
- ⚖️ **Zero-sum** — total value across all positions remains constant at 1 USDC.  
- 💧 **Unified liquidity** — all positions draw from one shared pool of capital.  
- ⚡ **Instant start** — synthetic liquidity allows trading from launch.  

## Further Reading

👉 [**Technical Overview**](TechnicalReadMe.md)

👉 [**Smart Contracts Index**](../ContractsIndex.md).

