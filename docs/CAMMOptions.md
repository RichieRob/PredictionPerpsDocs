# Composite AMM Pricing Overview

## Key Properties

- **Centralized Pricing**  
  The CAMM sets prices for all outcomes in one place, ensuring consistency across the entire market.  

- **Always-On Liquidity**  
  Traders can buy or sell at any time without waiting for a counterparty.  

- **Path Independence**  
  The cost to move from one state to another depends only on the final state, not on the sequence of trades.  

- **Bounded Risk by Design**  
  The CAMM itself never takes uncollateralized exposure. All solvency rules are enforced by the **MarketController**, which ensures that every position is fully backed (`v > 0`, `L_k ≥ 0`). The CAMM simply provides quotes within those bounds.  


## Example Solutions

Different pricing rules can be plugged into the CAMM, depending on the desired trade-offs:

1. **Logarithmic Market Scoring Rule (LMSR)**  
   - Smooth, continuous price adjustments.  
   - Strong theoretical guarantees with bounded loss.  
   - Widely used in prediction markets.  
   - **References:**  
     - [Robin Hanson, *Combinatorial Information Market Design* (2003)](https://mason.gmu.edu/~rhanson/combobet.pdf)  
     - [Robin Hanson, *Logarithmic Market Scoring Rules for Modular Combinatorial Information Aggregation* (2007)](https://www.gwern.net/docs/economics/2007-hanson.pdf)  

2. **Elliptical / Circle Cost Functions**  
   - Generalizations of constant-product AMMs (like Uniswap).  
   - Symmetric, easy-to-compute pricing surfaces.  
   - Gas-friendly for on-chain use.  
   - **References:**  
     - [Yunhao Wang, *Automated Market Makers for Decentralized Finance* (2020)](https://arxiv.org/abs/2009.01676)  
     - [Yunhao Wang, *Implementing Automated Market Makers with Constant Ellipse / Circle* (2021)](https://arxiv.org/abs/2103.03699)  

3. **Custom Hybrid Models**  
   - Combine features of scoring rules and constant-product styles.  
   - Tunable for different market types (e.g., sports, financial, multi-outcome).  
   - **References:**  
     - [Othman et al., *Practical Liquidity-Sensitive Automated Market Makers via Convex Risk Measures* (2013)](https://www.eecs.harvard.edu/cs286r/courses/fall13/papers/othman13.pdf)  
     - [Uniswap V3 Core Docs – Concentrated Liquidity](https://docs.uniswap.org/concepts/protocol/overview)  

---

## Summary

The CAMM is **modular**:  
- The **MarketController** guarantees solvency and collateralization.  
- The **CAMM** provides consistent and efficient pricing across all outcomes.  
- Pricing models (LMSR, ellipse, circle, hybrid) can be swapped in without affecting the underlying guarantees.  

This separation of roles ensures bounded risk, scalable pricing, and flexibility to adapt to different market types.  
