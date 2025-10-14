# How the Heap System Works

The heap system efficiently tracks the **smallest tilt value** (and its position) across n positions.

---

## 1. Grouping Positions into Blocks

Positions are divided into fixed-size **blocks of 16**:

- Each block stores:  
  - `minVal`: the smallest tilt value in that block  
  - `minId`: the position ID of that smallest tilt  

Example:  
- Positions 0–15 → block 0  
- Positions 16–31 → block 1  
- Positions 32–47 → block 2  

This reduces `n` total positions into about `n / 16` blocks.  
Each block summarises its local minimum.

---

## 2. Building a 4-ary Heap of Blocks

Each block’s `minVal` is stored in a **4-ary min-heap**:

- Every node in the heap represents a block.  
- Each node can have up to 4 children.  
- The heap property:  
  > A parent’s key ≤ all of its children’s keys.

As a result:

- The **heap root (index 0)** always represents the block with the smallest `minVal`.  
- No ordering is required between siblings
- Only parent/child relationships matter.

---

## 3. Updating When a Tilt Changes

When a position’s tilt changes:

1️⃣ **Identify the block:**  
   `blockId = positionId / 16`

2️⃣ **Update the stored tilt.**

3️⃣ **Update the block minimum:**  

   - If the changed position isn’t the smallest in the block and didn’t become smaller, stop (**O(1)**).  
   - If it becomes the new smallest, update `(minId, minVal)` and fix its position in the heap (**O(log₄(n / 16))**).  
   - If it was the smallest but got larger, rescan the 16 positions to find the new min, then fix in the heap (**O(16 + log₄(n / 16))**).

---

## 4. Heap Adjustment

When a block’s `minVal` changes, the heap may need to be re-ordered to maintain the parent ≤ children rule.  
Two processes handle this:

### Bubble Up (value decreased)
- Compare with parent.  
- If smaller, swap.  
- Repeat until it’s no longer smaller or reaches the root.  
→ 1 comparison per step, up to **log₄(n / 16)** steps.

### Bubble Down (value increased)
- Compare with up to 4 children.  
- Swap with the smallest child if needed.  
- Repeat until it’s no longer larger than its children.  
→ 4 comparisons per step, up to **log₄(n / 16)** steps.

This asymmetry (1 comparison up vs 4 down) is what makes the design efficient in practice.

---

## 5. Getting the Global Minimum

At any time:
- The **heap root (index 0)** gives the block with the smallest `minVal`.  
- That block’s `(minId, minVal)` give the smallest tilt and its position.

→ Constant-time lookup (**O(1)**).

---

### 6. Why It’s Efficient

| Action | Work | Typical Cost |
|---------|------|--------------|
| Update non-min | none | O(1) |
| Update block min | bubble up/down | O(log₄(n / 16)) |
| Rescan block | 16 values | O(16 + log₄(n / 16)) |
| Get global min | none | O(1) |

With, for example, `n = 10,000` positions:  
- `n / 16 = 625` blocks  
- `log₄(625) ≈ 5`  
- Heap depth **L = 6** (since 1 + 4 + 16 + 64 + 256 + 1024 ≥ 625)  
- Worst-case update (rescan + bubble-down) = **16 + 4·(L−1) = 36 steps**

So even for 10,000 positions, a full rescan and heap fix takes only a few dozen operations —  
logarithmic, not linear, growth.

---

### Worst-case Steps by n

| n (positions) | Blocks ⌈n/16⌉ | Levels L | Bubble-Up max (L−1) | Bubble-Down max 4·(L−1) | Rescan+Fix max 16 + 4·(L−1) |
|--------------:|--------------:|---------:|---------------------:|-------------------------:|----------------------------:|
| 1             | 1             | 1        | 0                    | 0                        | 16                          |
| 10            | 1             | 1        | 0                    | 0                        | 16                          |
| 100           | 7             | 3        | 2                    | 8                        | 24                          |
| 1,000         | 63            | 4        | 3                    | 12                       | 28                          |
| 10,000        | 625           | 6        | 5                    | 20                       | 36                          |
| 1,000,000     | 62,500        | 9        | 8                    | 32                       | 48                          |

---

### Key Takeaways

- The heap stays extremely shallow — only 6 levels for 10,000 positions and 9 for a million.  
- Bubble **up** checks one parent per level; bubble **down** scans up to 4 children per level.  
- A full rescan and heap fix involves at most a few dozen comparisons, even at large scales.  
- Global min lookup (`getMinTilt`) remains **O(1)** — instant and gas-cheap.

---

**Summary:**  
Each block maintains its own minimum; the heap maintains order among those block minima.  
When a value changes, only the affected block and its path in the heap are updated.  
The smallest tilt in the entire system is always stored at the heap root, instantly accessible.


## Why `B = 16` and a 4-ary heap (`d = 4`) are sensible

**Block size `B = 16`**
- **Cheap worst-case rescan:** when a block’s current min worsens, you rescan exactly 16 values — a tiny, fixed cost on-chain.
- **Good constant factors:** smaller `B` lowers rescan cost but increases the number of blocks (and heap depth); larger `B` saves heap work but makes rescans expensive. `B = 16` sits in the sweet spot.
- **Simple math & indexing:** `blockId = positionId / 16` (0-indexed); power-of-two division is optimizer-friendly and easy to reason about.

**4-ary heap (`d = 4`)**
- **Shallow tree:** with ~`n/16` blocks, depth is ~`log₄(n/16)`. For typical sizes (e.g., `n = 5k–10k`), that’s ~**5–6 levels**.
- **Balanced per-level work:** bubbling **down** scans up to 4 children; bubbling **up** checks only one parent. Going higher arity reduces depth but adds more child checks; lower arity (binary/ternary) increases swaps due to extra levels. `d = 4` is a pragmatic middle ground.
- **Predictable worst case:** “rescan + fix” costs ≈ **`16 + 4·(L−1)`** comparisons, where `L` is heap levels — a few dozen ops even at large `n`.

**Bottom line:** `B = 16, d = 4` gives small, fixed block work and a shallow heap with low, predictable adjustment cost, while keeping the implementation simple and gas-friendly.
