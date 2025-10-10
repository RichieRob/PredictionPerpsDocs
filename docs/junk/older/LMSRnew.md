# Logarithmic Market Scoring Rule (LMSR)

## Introduction

The **Logarithmic Market Scoring Rule (LMSR)** is one of the most widely used automated market maker mechanisms for prediction markets. It was originally proposed by **Robin Hanson (2003, 2007)** as part of his work on market scoring rules. The LMSR provides a simple, closed-form pricing function with bounded loss for the market maker, while ensuring liquidity at all times.

## Cost Function

The LMSR defines a **cost function** \( C(\mathbf{q}) \), where  
\(\mathbf{q} = (q_1, q_2, \dots, q_n)\) represents the outstanding quantities of each of the \(n\) outcome securities. The cost function is:

\[
C(\mathbf{q}) = b \cdot \ln \left( \sum_{i=1}^{n} e^{q_i / b} \right)
\]

- \(q_i\): outstanding shares of security \(i\)  
- \(b > 0\): liquidity parameter (controls sensitivity of prices to order size)

## Instantaneous Price

The instantaneous price of outcome \(i\) is the partial derivative of the cost function with respect to \(q_i\):

\[
p_i(\mathbf{q}) = \frac{\partial C(\mathbf{q})}{\partial q_i} 
= \frac{e^{q_i / b}}{\sum_{j=1}^{n} e^{q_j / b}}
\]

This ensures:

\[
\sum_{i=1}^{n} p_i(\mathbf{q}) = 1
\]

## Properties

- **Bounded Loss**: The maximum loss for the market maker is bounded by \(b \cdot \ln(n)\).  
- **Liquidity Control**: Larger \(b\) values provide more liquidity (prices change slowly with trades), while smaller \(b\) values make prices more sensitive to trades.  
- **Path Independence**: The total cost to reach a state \(\mathbf{q}\) is independent of the sequence of trades.  

## References

- Hanson, R. (2003). *Combinatorial Information Market Design*. Information Systems Frontiers, 5(1), 107–119.  
- Hanson, R. (2007). *Logarithmic Market Scoring Rules for Modular Combinatorial Information Aggregation*. Journal of Prediction Markets, 1(1), 3–15.  
