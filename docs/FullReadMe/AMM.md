---
comments: true
---

# LMSR as O(1)

This AMM implements a **closed-form version** of Robin Hanson’s  
*Logarithmic Market Scoring Rule (LMSR)*  
(*Combinatorial Information Market Design*, 2003; *Journal of Prediction Markets*, 2007).

It supports both **BACK** (buying outcome *i*) and **true LAY** (buying *not-i*) orders.  
All updates are done in **O(1)** time using a cached decomposition of the exponential sum.

---

## Part 1 — What is LMSR and What Are Its Formulas

### 1.1 What Is a Cost Function

A **cost function** defines the total money required to reach a given market state.  
It maps the current share vector \( \mathbf{q} = (q_1, q_2, \ldots, q_n) \)  
to a single scalar representing the *cumulative cost* of all outstanding positions:

$$
C : \mathbb{R}^n \rightarrow \mathbb{R}.
$$

When a trade occurs, the state changes by  
\( \Delta = (\Delta_1, \Delta_2, \ldots, \Delta_n) \).  
The **cost of that trade** is the difference in total cost between the new and old states:

$$
m = C(\mathbf{q} + \Delta) - C(\mathbf{q}).
$$

---

### 1.2 LMSR Cost Function

In the **Logarithmic Market Scoring Rule (LMSR)**, define the **partition function**:

$$
Z(\mathbf{q}) = \sum_{j=1}^{n} e^{q_j / b}.
$$

The **cost function** is then:

$$
C(\mathbf{q}) = b \ln\big( Z(\mathbf{q}) \big),
$$

where  

- \( q_j \) — total outstanding shares for outcome \(j\)  
- \( b > 0 \) — liquidity parameter (larger \(b\) → deeper market)  
- \( n \) — number of outcomes.

---

### 1.3 Cost of Changing State

A trade changes the share vector by \( \Delta \), producing a new market state \( \mathbf{q} + \Delta \).

Define the partition functions **before** and **after** the trade using the same \(Z(\cdot)\):

$$
Z_{\text{old}} = Z(\mathbf{q}),
\qquad
Z_{\text{new}} = Z(\mathbf{q} + \Delta).
$$

Then the corresponding costs are:

$$
C(\mathbf{q}) = b \ln(Z_{\text{old}}),
\qquad
C(\mathbf{q} + \Delta) = b \ln(Z_{\text{new}}).
$$

The **trade cost** is the difference:

$$
m = C(\mathbf{q} + \Delta) - C(\mathbf{q}).
$$

Expanding step by step:

$$
m = b \ln(Z_{\text{new}}) - b \ln(Z_{\text{old}})
$$

$$
m = b [ \ln(Z_{\text{new}}) - \ln(Z_{\text{old}}) ]
$$

$$
m = b \ln\left( \frac{Z_{\text{new}}}{Z_{\text{old}}} \right)
$$

---

### 1.4 Marginal Prices

Instantaneous prices are the *partial derivatives* of the cost function \(C(\mathbf{q})\)  
with respect to each outcome’s share count \(q_i\):

$$
p_i = \frac{\partial C}{\partial q_i}.
$$

Substituting the LMSR cost function \(C(\mathbf{q}) = b \ln(Z)\) with \(Z = \sum_j e^{q_j / b}\):

$$
p_i = \frac{e^{q_i / b}}{Z}.
$$

They always satisfy the normalization condition:

$$
\sum_i p_i = 1.
$$

- \(p_i\): price of **BACK(i)**  
- \(1 - p_i\): price of **LAY(not-i)**

---

### 1.5 BACK Formulas (Hanson 2003)

For a BACK(i) position:

- **Cost (for buying \(t\) tokens):**

  $$
  m = b \ln\left( 1 - p_i + p_i e^{t/b} \right)
  $$

- **Quantity (tokens received for spend \(m\)):**

  $$
  t = b \ln\left( 1 + \frac{e^{m/b} - 1}{p_i} \right)
  $$

Both formulas are closed-form and **O(1)** to compute.  
[Full derivation →](#appendix-a-back-derivations)

---

## Part 2 — Expanding LMSR for LAY Positions

### 2.1 Price of LAY(not-i)

From the definition of \(p_i\):

$$
1 - p_i = \frac{\sum_{j\neq i} e^{q_j / b}}{\sum_j e^{q_j / b}}.
$$

Thus, the **LAY price** is exactly the complement of the **BACK** price.  
[Proof →](#appendix-b-lay-derivation)

---

### 2.2 LAY Formulas

For a **LAY(not-i)** position:

- **Cost (for buying \(t\) tokens):**

  $$
  m = b \ln\left( p_i + (1 - p_i)e^{t/b} \right)
  $$

- **Quantity (tokens received for spend \(m\)):**

  $$
  t = b \ln\left( \frac{e^{m/b} - p_i}{1 - p_i} \right)
  $$

These are the **dual** forms of the BACK equations.  
[Full derivation →](#appendix-b-lay-derivation)

---

## Part 3 — Making LMSR O(1)

In the standard LMSR, every price and cost term depends on the **partition function**:

$$
Z = \sum_i e^{q_i / b},
$$

which must be recomputed after each trade, making the process **O(n)** per trade.

To make the system **O(1)**, we separate each \( q_i \) into a **global** and **local** component.

---

### Step 1 — Decompose Each Outcome

Write every outcome as:

$$
q_i = U_{\text{all}} + u_i,
$$

where  

- \(U_{\text{all}}\) is a global shift applied equally to every outcome, and  
- \(u_i\) is the local deviation for outcome \(i\).

---

### Step 2 — Factor the Exponential

Substitute this decomposition into the exponential term used in the LMSR sum:

$$
e^{q_i / b} = e^{(U_{\text{all}} + u_i) / b}.
$$

Expanding the exponent gives:

$$
e^{q_i / b} = e^{U_{\text{all}} / b} \, e^{u_i / b}.
$$

Now apply this to every term inside the partition function:

$$
\sum_i e^{q_i / b}
  = \sum_i \big( e^{U_{\text{all}} / b} \, e^{u_i / b} \big)
  = e^{U_{\text{all}} / b} \sum_i e^{u_i / b}.
$$

The **global term** \( e^{U_{\text{all}} / b} \) factors out because it is identical for every outcome.

---

### Step 3 — Define Cached Quantities

To simplify notation, define:

$$
G = e^{U_{\text{all}} / b}, \qquad R_i = e^{u_i / b}.
$$

Then the partition function becomes:

$$
Z = \sum_i e^{q_i / b} = G \sum_i R_i = G S,
$$

where \( S = \sum_i R_i \).

This gives:

$$
p_i = \frac{R_i}{S}.
$$

---

### Step 4 — Updating the Cached Terms After a Trade

Each trade modifies the market in two ways:

1. It applies a **global shift** to all outcomes  
   (for example, when total market liquidity changes).  

2. It applies a **local adjustment** to the traded outcome.  

---

Because the partition function is written as:

$$
Z = G \, S
$$

and

$$
G = e^{U_{\text{all}} / b}, 
\qquad
S = \sum_i e^{u_i / b},
$$

we can update only the affected terms  
instead of recalculating every exponential.

---

#### What changes when a trade happens

**1. Global multiplier**

The global variable \( U_{\text{all}} \)  
is shared across *all* outcomes.  

From its definition:

$$
G = e^{U_{\text{all}} / b}.
$$

---

When the market experiences a global movement  
of \( \Delta U_{\text{other}} \),  
the new value becomes:

$$
U_{\text{all}}' = U_{\text{all}} + \Delta U_{\text{other}}.
$$

---

Substitute this into the definition of \( G \):

$$
G' = e^{U_{\text{all}}' / b}.
$$

$$
G' = e^{(U_{\text{all}} + \Delta U_{\text{other}}) / b}.
$$

---

Factor out the previous term \( e^{U_{\text{all}} / b} \):

$$
G' = e^{U_{\text{all}} / b} \, e^{\Delta U_{\text{other}} / b}.
$$

Recognizing \( e^{U_{\text{all}} / b} = G \),  
we obtain the update rule:

$$
G' = G \, e^{\Delta U_{\text{other}} / b}.
$$

---

**2. Local multiplier**

Each outcome \(i\) has its own *local component* \(u_i\),  
which determines its relative deviation from the global term \(U_{\text{all}}\).

From the definitions:

$$
q_i = U_{\text{all}} + u_i,
$$

and

$$
R_i = e^{u_i / b}.
$$

---

When a trade occurs on outcome \(k\),  
the market applies two separate adjustments:

- a **global shift** \( \Delta U_{\text{other}} \),  
- and a **local shift** \( \Delta U_k \) specific to outcome \(k\).

After the trade:

$$
U_{\text{all}}' = U_{\text{all}} + \Delta U_{\text{other}},
$$

$$
u_k' = u_k + (\Delta U_k - \Delta U_{\text{other}}).
$$

The subtraction ensures that the local term \(u_k\)  
captures only the *relative* movement of outcome \(k\)  
compared to the global movement shared by all outcomes.

---

Now compute the new local multiplier:

$$
R_k' = e^{u_k' / b}.
$$

$$
R_k' = e^{(u_k + \Delta U_k - \Delta U_{\text{other}}) / b}.
$$

Factor out the previous value \( e^{u_k / b} \):

$$
R_k' = e^{u_k / b} \, e^{(\Delta U_k - \Delta U_{\text{other}}) / b}.
$$

Recognizing \( e^{u_k / b} = R_k \),  
we obtain the update rule:

$$
R_k' = R_k \, e^{(\Delta U_k - \Delta U_{\text{other}}) / b}.
$$


**3. Running sum**

The cached sum \(S = \sum_i R_i\)  
can be updated incrementally —  
remove the old \(R_k\) and add the new one:

$$
S' = S - R_k + R_k'.
$$

All other \(R_i\) remain unchanged.

---

#### Why this matters

By reusing the cached values \(G\), \(R_i\), and \(S\),  
we never need to re-evaluate every exponential term \( e^{q_j / b} \).  

After each trade, only:

- one global scalar \(G\),  
- one local scalar \(R_k\), and  
- the running sum \(S\)

are modified.

---

This allows prices and trade costs to be recalculated immediately,  
without summing over all outcomes —  
efficient, stable, and perfectly exact regardless of market size.



## Part 4 — Appendices

### Appendix A — BACK Derivations

#### A.1 BACK Buy — Cost for size \(t\)

$$
Z_{\text{old}} = \sum_j e^{q_j/b}, \qquad p_i = \frac{e^{q_i/b}}{Z_{\text{old}}}.
$$

A BACK(i) buy of size \(t\):

- \( \Delta_i = t \)  
- \( \Delta_j = 0 \) for \( j \neq i \)

Compute:

$$
Z_{\text{new}} = e^{(q_i + t)/b} + \sum_{j\neq i} e^{q_j/b}
$$

$$
Z_{\text{new}} = e^{t/b} e^{q_i/b} + (Z_{\text{old}} - e^{q_i/b})
$$

$$
\frac{Z_{\text{new}}}{Z_{\text{old}}} = (1 - p_i) + p_i e^{t/b}
$$

Hence:

$$
m = b \ln\left( 1 - p_i + p_i e^{t/b} \right)
$$

---

#### A.2 BACK Buy — Quantity \(t\) from spend \(m\)

$$
\frac{m}{b} = \ln(1 - p_i + p_i e^{t/b})
$$

$$
e^{m/b} = 1 - p_i + p_i e^{t/b}
$$

$$
t = b \ln\left( 1 + \frac{e^{m/b} - 1}{p_i} \right)
$$

---

### Appendix B — LAY Derivations

#### B.1 LAY(not-i) Buy — Cost for size \(t\)

$$
Z_{\text{new}} = e^{q_i/b} + e^{t/b}\left( Z_{\text{old}} - e^{q_i/b} \right)
$$

$$
\frac{Z_{\text{new}}}{Z_{\text{old}}} = p_i + (1 - p_i)e^{t/b}
$$

$$
m = b \ln\left( p_i + (1 - p_i)e^{t/b} \right)
$$

---

#### B.2 LAY(not-i) Buy — Quantity \(t\) from spend \(m\)

$$
\frac{m}{b} = \ln\left( p_i + (1 - p_i)e^{t/b} \right)
$$

$$
e^{m/b} = p_i + (1 - p_i)e^{t/b}
$$

$$
t = b \ln\left( \frac{e^{m/b} - p_i}{1 - p_i} \right)
$$

---

#### B.3 Dual Relationship (BACK ↔ LAY)

$$
m_{\text{LAY}}(p_i, t) = m_{\text{BACK}}(1 - p_i, t)
$$

$$
t_{\text{LAY}}(p_i, m) = t_{\text{BACK}}(1 - p_i, m)
$$

---

### References

- **Hanson, R. (2003)** — *Combinatorial Information Market Design*, George Mason University.  
- **Hanson, R. (2007)** — *Logarithmic Market Scoring Rules for Modular Combinatorial Information Aggregation*, *Journal of Prediction Markets*, 1(1).  
- **Abernethy, J., Chen, Y., Wortman Vaughan, J. (2011)** — *Efficient Market Making via Convex Optimization*, EC’11.

## Further Reading

For the full implementation of the code of the LSMR AMM in Prediction Perps see [**LMSRAMM.sol**](../Contracts/AMM.sol.md) 

For discussion on the internal ledger accounting which supports the implentation of the AMM start with [**Ledger Overview**](./Accounting/StandardLiquidity/LedgerOverview.md) 