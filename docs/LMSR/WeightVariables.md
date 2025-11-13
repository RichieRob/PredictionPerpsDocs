# LMSR Weighting Variables: q, U, R 

**core weighting variables** 

---

## 1. Core Definitions

### **q — Total Outstanding Exposure Vector**

For an n-outcome market:

\[
q = (q_1, q_2, \dots, q_n)
\]

Each \( q_i \) is the total outstanding exposure for outcome *i*.

---

## 2. Global + Local Decomposition


\[
q_i = U_{\text{all}} + u_i
\]

Where:

- **\( U_{\text{all}} \)** — *global shift*  
- **\( u_i \)** — *local deviation* for outcome *i*


---

## 3. R Values (Exponentials of Local Deviation)

\[
R_i = e^{u_i / b}
\]

Where **b** is the LMSR liquidity parameter.


---

## 4. Deltas and Update Rules

During a trade:

### **Global shift update**

\[
U_{\text{all}}' = U_{\text{all}} + \Delta U_{\text{rest}}
\]

### **Local update for the traded outcome k**

\[
u_k' = u_k + (\Delta U_k - \Delta U_{\text{rest}})
\]

---

## Summary Table

| Symbol | Meaning |
|--------|---------|
| \( q_i \) | Total outstanding exposure for outcome *i* |
| \( U_{\text{all}} \) | Global shift applied to all outcomes |
| \( u_i \) | Local deviation for outcome *i* |
| \( R_i = e^{u_i/b} \) | - |
| \( \Delta U_k \) | Update for outcome *k* |
| \( \Delta U_{\text{rest}} \) | Globally distributed update |

---

