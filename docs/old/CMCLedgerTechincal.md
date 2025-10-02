# CMC Ledger Technical Details

## Ledger Accounting

The internal ledger tracks positions for each Market Maker, ensuring non-negative posiitions are maintained per outcome (\( L_k \geq 0 \)). 
### Ledger Structure

#### Uniform Credit (v)

\( v \) (`int256`): Represents vUSDC credit, providing a uniform position across all outcomes, similar to a balanced "back all" position. It is adjusted for lay positions to ensure uniform exposure to "all other outcomes." For dynamic/expanding markets, \( v > 0 \) must hold to guarantee positive claims for new outcomes. For finite markets, \( v \) can become negative after balanced redemptions, as the invariant prioritizes \( L_k \geq 0 \) over uniform positivity. Using signed `int256` allows direct handling of negative \( v \) in finite cases without additional offsets.

#### Tilt Mapping

`tilt` (`mapping(uint256 => int128)`): Tracks signed deviations per outcome ID (\( k \)), allowing positive adjustments (for back positions, increasing exposure to \( k \)) or negative adjustments (for back or lay positions, reducing exposure to \( k \)). The use of signed `int128` enables precise tracking of deviations from the uniform credit \( v \). For lay positions, negative `tilt[k]` offsets the increase in \( v \), ensuring the claim on outcome \( k \) remains unchanged while increasing claims on all other outcomes, reflecting the complementary nature of lay bets.

#### Effective Claim per Outcome

The effective claim for outcome \( k \) is \( L_k = v + \text{tilt}[k] \geq 0 \), an invariant enforced across all operations to ensure non-negative claims.

#### Helpers for O(1) Checks

`minLk` (`uint256`): Tracks the smallest \( L_k \) value.

`minLkId` (`uint256`): Identifies the outcome ID for `minLk`.

`secondMinLk` (`uint256`): Tracks the second-smallest \( L_k \) value.

`secondMinLkId` (`uint256`): Identifies the outcome ID for `secondMinLk`.

These helpers are updated lazily when `tilt[k]` or \( v \) changes, avoiding \( O(n) \) scans and enabling fast validation against negative \( L_k \).

### Accounting Invariant

The sum of all \( L_k \) represents the CAMM’s total claim. Operations like deposits, redemptions, mints, or burns preserve or adjust this sum in a controlled manner. All \( L_k \geq 0 \) is the core invariant for collateralization.

#### Handling v in Finite vs. Dynamic Markets

For dynamic/expanding markets (unknown \( n \)), \( v > 0 \) is strictly enforced to ensure new outcomes inherit a positive uniform claim (\( L_k = v \) for untouched tilts).

For finite, non-expanding markets (known \( n \)), balanced redemptions allow withdrawal up to \( U \leq \min L_k \). This updates \( v \leftarrow v - U \), which can make \( v < 0 \) if prior burns created positive tilts (increasing some \( L_k > v \)). However, new \( L_k' = L_k - U \geq 0 \) holds, as \( U \leq \min L_k \). In code, with `v` as `int256`, negative values are directly supported. Example:

- Initial: \( v = 10 \), \( \text{tilt}[0] = 0 \), \( \text{tilt}[1] = 0 \), \( L_0 = 10 \), \( L_1 = 10 \), \( \min L_k = 10 \).
- Burn back 0 (\( Q = 3 \)): \( \text{tilt}[0] += 3 = 3 \), \( L_0 = 13 \), \( L_1 = 10 \), \( \min L_k = 10 \).
- Burn back 1 (\( Q = 4 \)): \( \text{tilt}[1] += 4 = 4 \), \( L_0 = 13 \), \( L_1 = 14 \), \( \min L_k = 13 \).
- Redeem \( U = 13 \): \( v = 10 - 13 = -3 \), \( L_0 = -3 + 3 = 0 \), \( L_1 = -3 + 4 = 1 \) (both \( \geq 0 \)).

For dynamic \( n \), new outcomes default to \( L_k = v \) (with `tilt[k] = 0`), inheriting uniform credits without explicit updates.