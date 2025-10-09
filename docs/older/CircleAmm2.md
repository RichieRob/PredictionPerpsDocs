Chat GPT


# Constant Ellipse / Circle Cost-Function AMM

This page documents a **constant-ellipse** cost-function market maker (and its symmetric **circle** special case) and shows how to implement it as an AMM. We provide the **general \(n\)-asset** form and the **binary** specialization in terms of live balances \(h_R,h_G\). All formulas here are **fee-free**.

---

## References

- Yunhao Wang (2020), *Automated Market Makers for Decentralized Finance (DeFi)*, arXiv:2009.01676.
- Yunhao Wang (2021), *Implementing Automated Market Makers with Constant Ellipse / Circle*, arXiv:2103.03699.

---

## 1) Elliptical cost function (general \(n\) assets)

Let \(q=(q_1,\dots,q_n)\) be the inventory vector. The constant-ellipse quadratic **cost potential** is

$$
C(q) = \sum_{i=1}^{n} (q_i-a)^2 + b \sum_{i\ne j} q_i q_j
$$

Trade **cost** for a state change \(q\to q'\) is

$$
\text{cost}(q\to q') = C(q') - C(q)
$$

**Instantaneous (cash) price** of asset \(i\) is the marginal

$$
P_i(q) = \frac{\partial C}{\partial q_i}
$$

$$
P_i(q) = 2(q_i-a) + b \sum_{j\ne i} q_j
$$

If you want probability-style quotes, normalize

$$
\pi_i(q) = \frac{P_i(q)}{\sum_{j=1}^{n} P_j(q)}
$$

**Convexity (sketch)**  
The Hessian is

$$
H = 2 I + b\left(\mathbf{1}\mathbf{1}^\top - I\right)
$$

For \(n=2\) the PSD condition is \(-2 \le b \le 2\).

**Block trade (exact) — buy \(Q\) of asset \(k\)**

$$
D_k(Q) = C(q + Q e_k) - C(q)
$$

$$
D_k(Q) = Q^2 + B_k Q
$$

$$
B_k = 2(q_k-a) + b \sum_{j\ne k} q_j
$$

Given a spend \(D\), the **quantity** is

$$
Q_k(D) = \frac{-B_k + \sqrt{B_k^2 + 4D}}{2}
$$

These are add/mul plus one square root.

---

## 2) Circle implementation (symmetric ellipse)

Set \(b=0\) to obtain the **circle**. Two equivalent realizations are common.

### (A) Invariant form (Approach I)

Keep the scaled reserves on a fixed circle

$$
(\mu x - c)^2 + (\mu y - c)^2 = r^2
$$

The instantaneous **exchange rate** on the lower-left arc is

$$
\frac{d(\mu y)}{d(\mu x)} = - \frac{c - \mu x}{c - \mu y}
$$

A finite update \(x\to x' = x + \Delta x\) is projected back to the circle

$$
y' = c - \frac{1}{\mu}\sqrt{\,r^2 - (\mu x' - c)^2\,}
$$

$$
\Delta y = y - y'
$$

Choose the lower-left branch to keep “supply ↑ ⇒ price ↑”.

### (B) Cost-function form (Approach II)

Represent the circle as a cost

$$
C(x,y) = (x - c)^2 + (y - c)^2
$$

**Spot prices** are marginals

$$
P_x = 2(x - c)
$$

$$
P_y = 2(y - c)
$$

A block trade has cost

$$
\text{cost} = C(\text{after}) - C(\text{before})
$$

---

## 3) AMM realization with balances

Two versions: general \(n\)-asset ellipse and the binary specialization.

### 3.1 General \(n\)-asset ellipse AMM

State is \(q=(q_1,\dots,q_n)\).

Cost is

$$
C(q) = \sum_{i=1}^{n} (q_i-a)^2 + b \sum_{i\ne j} q_i q_j
$$

Spot prices are

$$
P_i(q) = 2(q_i-a) + b \sum_{j\ne i} q_j
$$

Block trade cost is

$$
D_k(Q) = Q^2 + B_k Q
$$

Inverse (spend → quantity) is

$$
Q_k(D) = \frac{-B_k + \sqrt{B_k^2 + 4D}}{2}
$$

Optional complementary prices use

$$
\pi_i(q) = \frac{P_i(q)}{\sum_{j=1}^{n} P_j(q)}
$$

Path independence is guaranteed by

$$
\text{cost}(q\to q') = C(q') - C(q)
$$

### 3.2 Binary specialization \((h_R,h_G)\)

Identify \(x=h_R\) and \(y=h_G\). The ellipse cost is

$$
C(h_R,h_G) = (h_R - a)^2 + (h_G - a)^2 + b\, h_R h_G
$$

Spot prices are

$$
P_R(h_R,h_G) = 2(h_R - a) + b\, h_G
$$

$$
P_G(h_R,h_G) = 2(h_G - a) + b\, h_R
$$

Buy \(Q\) Red with \(h_G\) fixed

$$
D_R(Q) = Q^2 + \left(2(h_R - a) + b\, h_G\right) Q
$$

Given spend \(D\), the quantity is

$$
Q_R(D) = \frac{-B + \sqrt{B^2 + 4D}}{2}
$$

$$
B = 2(h_R - a) + b\, h_G
$$

Buy \(Q\) Green by swapping \(h_R \leftrightarrow h_G\).

Optional complementary prices use

$$
p_R = \frac{P_R}{P_R + P_G}
$$

$$
p_G = 1 - p_R
$$

### 3.3 Binary circle (perfect symmetry)

**Approach I (invariant)**

$$
(\mu h_R - c)^2 + (\mu h_G - c)^2 = r^2
$$

$$
\frac{d(\mu h_G)}{d(\mu h_R)} = - \frac{c - \mu h_R}{c - \mu h_G}
$$

$$
h_G' = c - \frac{1}{\mu}\sqrt{\,r^2 - (\mu h_R' - c)^2\,}
$$

**Approach II (cost)**

$$
C(h_R,h_G) = (h_R - c)^2 + (h_G - c)^2
$$

$$
P_R = 2(h_R - c)
$$

$$
P_G = 2(h_G - c)
$$

$$
\text{cost} = C(\text{after}) - C(\text{before})
$$

---

## Notes on parameters

Ellipse parameters are \((a,b)\).  
The center parameter \(a\) shifts the inventory baseline.  
The coupling parameter \(b\) controls curvature and cross-effect.  
For \(n=2\) the convex branch requires \(-2 \le b \le 2\).

Circle parameters are \((c,r)\) and optionally \(\mu\).  
Choose \((c,r)\) so the genesis point lies on the lower-left arc.
