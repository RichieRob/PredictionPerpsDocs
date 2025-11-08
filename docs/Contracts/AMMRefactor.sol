# Proposed Changes to `LMSRMarketMaker.sol` (formerly `amm.sol`)

## Overview

We propose refactoring the **amm.sol to enhance **readability**, **maintainability**, and **scalability**.

The key proposed changes include:

1. **Splitting into Libraries** – Modularize the contract logic into separate libraries, each handling a specific concern. This will reduce contract size and simplify commenting, testing, and reuse.
2. **Separating Market Initialization** – Move market-specific initialization out of the constructor into a new `initMarket` function. This allows a single deployed contract to support multiple markets, improving flexibility and gas efficiency.

> ⚙️ These changes do **not** alter the core LMSR (Logarithmic Market Scoring Rule) logic — they simply reorganize it for clarity and structure.

---

## 1 · Proposed Refactoring into Libraries

The current contract is **monolithic**, containing all math helpers, quoting logic, state updates, expansion logic, and initialization in one file.  
We propose extracting logical sections into **dedicated libraries**, using Solidity’s `library` pattern where functions operate on the contract’s state via `using ... for ...`.

### Proposed Libraries and Their Responsibilities

#### **`LMSRMathLib.sol`**
- Contains **pure mathematical helpers**, such as:
  - `expRatioOverB`
  - Fixed-point multiplication (`wmul`)
- Stateless and reusable.
- Uses `PRBMathSD59x18` for exponentials and logarithms.
- Example: computes expressions like `e^(x/b)`.

---

#### **`LMSRQuoteLib.sol`**
- Handles **all quoting functions**, e.g.:
  - `quoteBuyInternal`
  - `quoteSellInternal`
  - `quoteBuyForUSDCInternal`
- **View-only** — reads storage and computes prices/costs.
- Uses math from `LMSRMathLib`.
- Reads per-market storage such as `R`, `S_tradables`, etc.

---

#### **`LMSRUpdateLib.sol`**
- Handles the **core trade update logic**, e.g.:
  - `applyUpdateInternal`
- Mutates storage variables like `G`, `R`, and `S_tradables`.
- Computes **deltas** for global and local factors.
- Implements **O(1)** updates for efficiency.

---

#### **`LMSRExpansionLib.sol`**
- Handles **governor-only** functions for adding new positions:
  - `listPositionInternal`
  - `splitFromReserveInternal`
- Updates mappings such as:
  - `slotOf`, `ledgerIdOfSlot`
- Updates global state (`R`, `S_tradables`, `numOutcomes`).
- Ensures **price continuity** during market expansion.

---

#### **`LMSRInitLib.sol`**
- Handles **market initialization logic**:
  - `initMarketInternal`
- Sets up per-market state:
  - Loads priors, validates inputs, initializes arrays/mappings.
- Emits events for listed positions.

---

### Integration in the Main Contract

The **main contract** (`LMSRMarketMaker.sol`) will retain:

- **State variables**, primarily mapped by `marketId`.
- **Constructor**, now minimal.
- **Public/external functions** that call library internals.
- **Basic view helpers** (e.g. `_denom`, `_requireListed`).

Example usage:

```solidity
using LMSRMathLib for int256;
using LMSRQuoteLib for LMSRMarketMaker;
using LMSRUpdateLib for LMSRMarketMaker;
using LMSRExpansionLib for LMSRMarketMaker;
using LMSRInitLib for LMSRMarketMaker;
```

Library internals will access contract state via `self`, e.g.:
```solidity
self.R[marketId][slot];
```

✅ **Result**  
- Shorter, cleaner contract  
- Logical grouping of code  
- Easier testing and documentation  
- No change to economic logic

---

## 2 · Proposed Separation of Market Initialization

Currently, the constructor initializes a **single market** at deployment.  
We propose allowing **multi-market support** via a new `initMarket` flow.

### Constructor Changes

**Old (Single-Market):**
```solidity
constructor(address _ledger, address _usdc, uint256 _marketId, uint256 _mmId, ...) { ... }
```

**New (Shared Only):**
```solidity
constructor(address _ledger, address _usdc, address _governor) {
    ledger = _ledger;
    usdc = _usdc;
    governor = _governor;
}
```

- Accepts only **shared** parameters.
- Removes all market-specific initialization.

---

### State Variable Updates

Most state variables will become **mapped by `marketId`**, for example:

```solidity
mapping(uint256 => int256) public b;
mapping(uint256 => int256[]) public R;
mapping(uint256 => bool) public initialized;
```

- `b[marketId]` – LMSR liquidity parameter per market.  
- `initialized[marketId]` – Tracks whether setup has occurred.

Shared immutables (`ledger`, `usdc`, `governor`) remain global.

---

### `initMarket` Function

A new **`initMarket`** function will allow the governor to initialize markets individually.

**Parameters:**
- `_marketId`
- `_mmId`
- `_numInitial`
- `initialLedgerIds`
- `initialR`
- `_b`
- `reserve0`
- `_isExpanding`

**Flow:**
1. Validate inputs (`!initialized[marketId]`, correct array lengths).
2. Delegate setup to `LMSRInitLib.initMarketInternal`.
3. Initialize all per-market variables:
   - `G[marketId] = WAD`
   - Set up arrays and mappings.
4. Set `initialized[marketId] = true`.

**Example:**
```solidity
function initMarket(...) external onlyGovernor {
    require(_numInitial > 0 && _numInitial <= 4096, "bad n");
    this.initMarketInternal(_marketId, ...);
}
```

---

### Integration in Other Functions

- All public functions (e.g., `quoteBuy`, `buy`, `listPosition`) will now take `marketId` as **the first argument**.
- Functions will revert if `!initialized[marketId]`.
- Internal helpers will read per-market data using that ID.

✅ **Result:**  
A single deployed contract can host many LMSR markets with shared configuration, saving gas and simplifying management.

---

## 3 · Benefits of the Proposed Changes

| **Category** | **Benefit** |
|---------------|-------------|
| **Readability & Maintainability** | Smaller, focused files are easier to understand and modify. |
| **Reusability** | Libraries can be used in other contracts. |
| **Scalability** | One deployment supports multiple markets. |
| **Security** | Modular structure reduces risk of complex file errors. |
| **No Logic Change** | Core LMSR mechanics (quotes, updates, expansions) are unchanged. |

---

## 4 · Potential Next Steps

1. **Testing**
   - Verify library calls and state mutations behave identically.
   - Add unit tests for each module.

2. **Gas Optimization**
   - Analyze gas usage of modular calls.
   - Consider inlining hot paths if needed.

3. **Documentation**
   - Add NatSpec comments to every function.
   - Update developer docs to reflect multi-market architecture.

---

### ✅ Summary

This refactor preserves the LMSRMarketMaker’s core logic but transforms it into a **modern, modular architecture**:

- Multiple markets per contract  
- Dedicated libraries for math, quotes, updates, and expansion  
- Cleaner governance-controlled initialization  

Result: **A more maintainable, testable, and scalable foundation** for future prediction markets.



ADDITIONALLY

Adding an exectuationlibrary to take the exectutions out of the main body too.