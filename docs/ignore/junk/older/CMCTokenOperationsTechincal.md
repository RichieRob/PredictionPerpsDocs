# CMC Token and Operations Technical Details

## ERC-20 Token Minting and Creation

The CMC is the sole minter and burner of ERC-20 tokens, using lazy minting to externalize ledger positions only when required.

### Token Structure

For each outcome ID (`uint256`):

- **Back Token**: An ERC-20 token (e.g., "Back Outcome 1") for betting on the outcome occurring.
- **Lay Token**: An ERC-20 token (e.g., "Lay Outcome 1") for betting against the outcome, effectively betting on all other outcomes.

Storage uses mappings from `outcomeId` to ERC-20 contract addresses (e.g., `backTokens[outcomeId]`, `layTokens[outcomeId]`).

### Creation Process

#### addOutcome Function

`addOutcome(uint256 outcomeId)`: Deploys or assigns new ERC-20 contracts for Back and Lay tokens (one-time, ~1M–2M gas per deployment). Initializes `tilt[outcomeId] = 0`. No ledger updates are needed for existing CAMMs; new outcomes inherit \( v \).

#### Dynamic n Support

Outcomes can be added at any time (e.g., via admin or oracle), with no gas cost until traded.

### Minting and Burning Operations

#### Lazy Minting

Tokens are minted only upon request, minimizing gas costs for internal operations.

#### Mint Back k (Q)

**Check**: \( L_k \geq Q \) (\( v + \text{tilt}[k] \geq Q \)).

**Update**: `tilt[k] -= Q` (using signed `int128`, without modifying \( v \)).

**Helper Update**: Adjust `minLk` if \( k \) was the min or second-min.

**Action**: Mint \( Q \) ERC-20 Back \( k \) tokens.

**Gas**: ~15k–20k (1 SSTORE for `tilt[k]`, ~5k; ERC-20 mint, ~10k–15k).

#### Burn Back k (Q)

**Action**: Burn \( Q \) ERC-20 Back \( k \) tokens.

**Update**: `tilt[k] += Q`.

**Helper Update**: Adjust `minLk` if needed.

**Gas**: ~15k–20k (1 SSTORE, ERC-20 burn).

#### Mint Lay k (Q)

**Check**: \( L_k \geq 0 \) post-update (\( v + Q + \text{tilt}[k] - Q = v + \text{tilt}[k] \geq 0 \), using `minLk` if \( k \) is min).

**Update**: \( v += Q \), `tilt[k] -= Q` (increases claims by \( Q \) on all non-\( k \) outcomes, no net change on \( k \) relative to prior \( L_k \); ensures \( v > 0 \) for dynamic markets).

**Helper Update**: Adjust `minLk` if \( k \) was min or second-min.

**Action**: Mint \( Q \) ERC-20 Lay \( k \) tokens.

**Gas**: ~20k–25k (2 SSTOREs for \( v \), `tilt[k]`, ~10k; ERC-20 mint, ~10k–15k).

#### Burn Lay k (Q)

**Action**: Burn \( Q \) ERC-20 Lay \( k \) tokens.

**Update**: \( v -= Q \), `tilt[k] += Q` (check \( v > 0 \) for dynamic markets post-update).

**Check**: \( L_k \geq 0 \) (sparse, using `minLk`).

**Helper Update**: Adjust `minLk` if needed.

**Gas**: ~15k–20k (2 SSTOREs, ERC-20 burn).

### Lay Adjustment via vUSDC

For a lay position on outcome \( k \) with quantity \( Q \):

- Increase \( v += Q \) to uniformly boost all \( L_k \), exposing the lay to all other outcomes (including future, unconceived ones).
- Decrease `tilt[k] -= Q` to offset the increase for outcome \( k \), resulting in no net change to \( L_k \) but adding \( Q \) to all non-\( k \) outcomes.

This approach works without knowing \( n \), as \( v \) is uniform and new outcomes inherit it. The sum of \( L_k \) increases by \( (n-1) \times Q \). Burning reverses these updates, maintaining \( O(1) \) efficiency and avoiding \( O(n) \) adjustments for non-\( k \) outcomes.

## Operations and Gas Efficiency

All core operations are \( O(1) \), leveraging sparse mappings and helper variables. No full scans are required for dynamic \( n \), as helpers ensure rapid invariant checks.

### Deposit Balanced (U vUSDC)

**Update**: \( v += U \) (ensure \( v > 0 \) for dynamic markets).

**Check**: Verify `minLk`.

**Gas**: ~20k–25k.

### Redeem Balanced (U vUSDC)

**Check**: \( U \leq \text{minLk} \).

**Update**: \( v -= U \) (allow \( v < 0 \) for finite markets; ensure \( v > 0 \) for dynamic).

**Helper Update**: Adjust `minLk`.

**Gas**: ~24k–30k.

### Add New Outcome

**Storage**: \( O(1) \), ~1M–2M gas if deploying ERC-20 contracts.

### Update Helpers

**Process**: Lazy updates on changes to `tilt[k]` or \( v \); check for new `minLk` (\( O(1) \)).