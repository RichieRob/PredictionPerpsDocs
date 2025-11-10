## Tokens created

Example of the tokens created when 4 positions Apple, Banana, Cucumber, Dragon Fruit are created in a market called Fruit.

### 🧩 Token Names

| Position       | Back Token Name              | Lay Token Name              |
|----------------|------------------------------|-----------------------------|
| Apple          | Back Apple in Fruit          | Lay Apple in Fruit          |
| Banana         | Back Banana in Fruit         | Lay Banana in Fruit         |
| Cucumber       | Back Cucumber in Fruit       | Lay Cucumber in Fruit       |
| Dragon Fruit   | Back Dragon Fruit in Fruit   | Lay Dragon Fruit in Fruit   |

---

### 💱 Token Tickers

| Position       | Back Token Ticker | Lay Token Ticker |
|----------------|------------------|-----------------|
| Apple          | **BAPL-FRT**     | **LAPL-FRT**    |
| Banana         | **BBAN-FRT**     | **LBAN-FRT**    |
| Cucumber       | **BCUC-FRT**     | **LCUC-FRT**    |
| Dragon Fruit   | **BDRF-FRT**     | **LDRF-FRT**    |

### 🔢 Token ID Structure

Each ERC-1155 token has a **unique 256-bit `tokenId`** formed from three components:

TokenId = (marketId << 64) | (positionId << 1) | isBack


- **marketId** — identifies which market the token belongs to  
- **positionId** — identifies the specific position within that market  
- **isBack** — `1` for Back tokens, `0` for Lay tokens  

This encoding ensures every Back/Lay token across all markets has a distinct ID.

---

### 🧮 Token ID Components

marketId = 0 as we assume this is the first market

| Token Type    | marketId | positionId | isBack |
|----------------|-----------|-------------|---------|
| Back Apple     | 0 | 0 | 1 |
| Lay Apple      | 0 | 0 | 0 |
| Back Banana    | 0 | 1 | 1 |
| Lay Banana     | 0 | 1 | 0 |
| Back Cucumber  | 0 | 2 | 1 |
| Lay Cucumber   | 0 | 2 | 0 |
| Back Dragon Fruit | 0 | 3 | 1 |
| Lay Dragon Fruit  | 0 | 3 | 0 |

