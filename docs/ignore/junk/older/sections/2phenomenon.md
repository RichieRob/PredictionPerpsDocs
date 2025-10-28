## The Phenomena
    
A Perpetual Bounded Phenomenon (PBP) arises from a sequence of discrete events with bounded outcomes.

Formally, a PBP is a process mapping natural numbers to a bounded interval:

$$
f: \mathbb{N} \to [a, b]
$$

where

$$
a \leq f(t) \leq b \quad \text{for all discrete time steps } t \in \mathbb{N}.
$$

Each step \( t \) produces an outcome:

$$
X_t \in \{0, 1, \dots, m\}.
$$

The cumulative value over a window of length \( n \) is:

$$
S = \sum_{k=0}^{n-1} X_{t-k}, \quad 0 \leq S \leq m n.
$$

A complementary measure captures the shortfall from the maximum:

$$
\overline{S} = m n - S.
$$

Thus, every PBP yields a pair \( (S, \overline{S}) \), representing achievement versus missed potential.

