# Rebasing Mechanism Sketch

## Introduction
This document outlines a rebasing vault smart contract in Solidity. Users deposit an underlying token (T) to receive a rebasing token (aT). The aT balance grows via periodic rebases, but new deposits remain fixed until activated at the next `rebase()` call. The rate at each checkpoint (`rebase_id = n`) applies to the period from `n-1` to `n`.

**Key Goals**:
- Support variable rates per rebase period.
- Efficient: No iteration over users or deposits in `rebase()`.
- User balances split into activated (rebasing, transferable) and pending (fixed until activation, non-transferable).
- Use a cumulative index with historical snapshots for accurate accounting.

**Assumptions**:
- Rebase rate is provided externally (complex calculation, not detailed).
- Scale factor: 1e18 for fixed-point math.
- ERC20-based with overrides for `balanceOf`, `totalSupply`, `transfer`, etc.
- Withdrawals distribute underlying T proportionally (vault accrues yield).

## Core Concepts

### Cumulative Index
- Global multiplier tracking growth since inception.
- Starts at `1e18`.
- Updated in `rebase()`: `new_index = old_index * (1e18 + rate) / 1e18`.
- Represents compounded rates from all rebases.

### Rebase ID and History
- `current_rebase_id`: Starts at 0, increments per `rebase()`.
- `cumulative_index_history[rebase_id]`: Stores `cumulative_index` after each rebase.
- Rate from `x` to `y`: `(cumulative_index_history[y] * 1e18 / cumulative_index_history[x]) - 1e18`.

### User Balance Parts
Each user has two balance components (no arrays):
1. **Activated Part (Part 1)**:
   - Stored as `user_effective_shares` (normalized shares).
   - Balance: `user_effective_shares * cumulative_index / 1e18`.
   - Grows with every rebase, reflecting all rates post-activation.
   - Transferable to other addresses.
2. **Pending Part (Part 2)**:
   - Stored as `user_pending_base` (raw amount) with `user_pending_entry_id` (activation rebase_id).
   - Fixed if `user_pending_entry_id > current_rebase_id`.
   - If activated (`entry_id <= current_rebase_id`), balance = `user_pending_base * cumulative_index / cumulative_index_history[entry_id]`.
   - Non-transferable; remains with depositor until merged.
   - Multiple deposits before a rebase accumulate in the same pending part.

### Global Tracking
- `effective_shares`: Sum of all `user_effective_shares`.
- `global_pending_base`: Total pending deposits (single `entry_id`).
- `global_pending_entry_id`: Pending group ID (one cohort at a time).

## Rebase Process
1. **Input**: Rate for period from `current_rebase_id` to `current_rebase_id + 1` (external).
2. **Update Index**: `cumulative_index = cumulative_index * (1e18 + rate) / 1e18`.
3. **Store History**: Increment `current_rebase_id`, set `cumulative_index_history[current_rebase_id] = cumulative_index`.
4. **Activate Pending**: If `global_pending_entry_id == current_rebase_id`:
   - Add `global_pending_base * 1e18 / cumulative_index` to `effective_shares`.
   - Reset `global_pending_base = 0`, `global_pending_entry_id = 0`.
5. **Effects**: Activated balances grow by rate; pending deposits activate without prior gains.

**Efficiency**: O(1), no user loops.

## Rate Handling
- **Rate at Checkpoint n**: Applies to period from `n-1` to `n`, used in `rebase()` to update `cumulative_index`.
- **Querying Rates**: Rate from `x` to `y` (y > x): `(cumulative_index_history[y] * 1e18 / cumulative_index_history[x]) - 1e18`.
- **Example**:
  - Rebase 1 (rate = 0.05e18): `history[1] = 1.05e18`.
  - Rebase 2 (rate = 0.03e18): `history[2] = 1.05e18 * 1.03 = 1.0815e18`.
  - Rate at checkpoint 2 (from 1 to 2): `(1.0815e18 / 1.05e18) - 1 = 0.03`.

## User Interactions

### Deposit
1. Merge pending if `user_pending_entry_id <= current_rebase_id` (see Merge).
2. Transfer T to vault.
3. Set `entry_id = current_rebase_id + 1`.
4. Add `amount` to `user_pending_base` (accumulate if same `entry_id`).
5. Set `user_pending_entry_id = entry_id` if unset.
6. Update globals: Add to `global_pending_base`, set `global_pending_entry_id` if needed.
7. Mint aT equal to `amount`.

**Note**: New deposits are fixed and non-transferable until next rebase.

### Withdraw
1. Merge pending if activated.
2. Compute total balance = activated + pending (fixed or rebased).
3. Require amount <= total.
4. Pro-rata reduce `user_effective_shares` and `user_pending_base`.
5. Update globals: Subtract from `effective_shares`, `global_pending_base` if applicable.
6. Burn aT, transfer proportional T (based on `totalSupply`).

### Transfer
1. Merge pending for sender and recipient if `user_pending_entry_id <= current_rebase_id`.
2. Compute sender's total balance (activated + pending), require amount <= total.
3. Calculate activated balance: `user_effective_shares[sender] * cumulative_index / 1e18`.
4. Determine transferable amount:
   - Only the activated part is transferable.
   - If amount <= activated balance, use only activated.
   - If amount > activated balance but <= total, fail (pending is non-transferable).
5. Reduce sender’s `user_effective_shares` by `amount * 1e18 / cumulative_index`.
6. Add to recipient’s `user_effective_shares` (same amount).
7. Update global `effective_shares` (no net change).
8. **Pending Note**: Sender’s `user_pending_base` and `user_pending_entry_id` remain unchanged (non-transferable). Recipient’s pending part is unaffected.
9. Emit Transfer event.

**Transfer Clarification**: Only activated balances (rebasing, from `user_effective_shares`) can be transferred. Pending balances (fixed, non-rebasing) stay with the sender until activated and merged, ensuring pending deposits are tied to the original depositor.

### Merge (Internal)
- If `user_pending_entry_id <= current_rebase_id`:
  - Convert: `delta_shares = user_pending_base * 1e18 / cumulative_index_history[user_pending_entry_id]`.
  - Add to `user_effective_shares` and `effective_shares`.
  - Clear `user_pending_base`, `user_pending_entry_id`.

### Balance Calculation (balanceOf)
- Activated: `user_effective_shares * cumulative_index / 1e18`.
- Pending:
  - If `entry_id > current_rebase_id`: `user_pending_base` (fixed).
  - Else: `user_pending_base * cumulative_index / cumulative_index_history[entry_id]`.
- Total: Sum of both.

### Total Supply
- Activated: `effective_shares * cumulative_index / 1e18`.
- Pending: `global_pending_base` if `global_pending_entry_id > current_rebase_id`, else 0.
- Total: Sum.

## Efficiency and Scalability
- **Storage**: Per-user: 3 slots. Global: Scalars + `cumulative_index_history` (grows with rebases).
- **Gas**:
  - `rebase()`: O(1).
  - User ops: O(1), at most one merge.
  - Views: O(1).
- **No Iteration**: Uses aggregates and history mapping.
- **Scalability**: Handles many users/deposits efficiently.

## Edge Cases
- First rebase: `rebase_id = 0` initializes correctly.
- No deposits: Skips activation.
- Multiple deposits: Accumulate in pending.
- Transfers: Only activated part moves; pending stays with sender.
- Zero rate: No effect.

This design ensures efficient rebasing with variable rates, proper handling of non-transferable pending deposits, and clear accounting.