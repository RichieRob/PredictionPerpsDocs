---
comments: true
---

# Market Initialisation

When creating a market, you provide a name and ticker for easy identification—think "Electric Vehicle Stocks" with ticker "EVSTK." This generates a unique ID automatically. Markets begin in expanding mode, meaning you can add as many positions as needed.

Adding positions involves giving each one a name and ticker, such as "Tesla" with "TSLA." The system assigns a unique ID within the market and creates Back and Lay tokens with prefixed labels for clarity: "Back Tesla Electric Vehicle Stocks" (ticker "BTSLA-EVSTK") and "Lay Tesla Electric Vehicle Stocks" ("LTSLA-EVSTK"). This metadata is stored on-chain and readable by wallets.

Some markets have a defined finite number of positions. For these, you call lockMarket, which stops the market from ever expanding to have more positions.

Throughout, solvency is maintained automatically, with expanding markets accounting for unlisted outcomes via an implicit "Other" bucket. The "Other" bucket is no longer present on locked (non-expanding) markets.