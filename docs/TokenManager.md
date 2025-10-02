# TokenManager Technical Details

## Overview

The **TokenManager** creates an ERC-20 contract representing each back and lay position and acts as the controller of all ERC-20 token contracts in the composite market, minting and burning tokens lazily and only on demand.

- Acts as a subordinate to the ledger, executing token operations based on ledger directives.

---

## Token Structure

The TokenManager creates and manages ERC-20 tokens, issuing them at the command of the ledger.

### Key Components

#### Back Tokens
- ERC-20 contracts (e.g., "Back Position 1") representing a position on the identifier.
- Minted lazily when requested.

#### Lay Tokens
- ERC-20 contracts (e.g., "Lay Position 1") representing the inverse position.
- Minted lazily on ledger command.

#### Storage
- Mappings from `positionId` (uint256) to contract addresses: `backTokens[positionId]` and `layTokens[positionId]`.
- Tokens are standard ERC-20, with the TokenManager as the sole minter/burner.

---

## Dynamic Position Support

Positions can be added anytime via `addPosition(k)` on ledger directive, deploying new ERC20 contracts as needed. New tokens are ready for lazy minting on demand.