## Tokenizing Principals

### Tokens \( T \) and \( \overline{T} \)


<div style="display: flex; justify-content: center;">

```mermaid
graph TD
    S["S"] -.->|peg mechanism| T((T))
    Sbar["S̅"] -.->|peg mechanism| Tbar((T̅))
    style T fill:#4CAF50,stroke:#333,stroke-width:2px,color:#fff
    style S fill:#4CAF50,stroke:#333,stroke-width:2px,color:#fff
    style Tbar fill:#FF5722,stroke:#333,stroke-width:2px,color:#fff
    style Sbar fill:#FF5722,stroke:#333,stroke-width:2px,color:#fff
```
</div>

### Constant Price Formula
To preserve the complementary dynamics inherent in \( S \) and \( \overline{S} \), we fix the prices of our tokens to a constant.

\[ P_T + P_{\overline{T}} = 1 \]

### Price Units

The constant price formula can be tied to any asset as needed. We envision this system primarily being priced in stablecoins, such as USDT or USDC. In this paper, we use USDC as shorthand for the pricing asset of choice.

### Enforcement of Constant Price Formula

The constant price relationship is enforced by allowing 1 \( T \) and 1 \( \overline{T} \) to be minted or burned at any time for 1 USDC.

<div style="display: flex; justify-content: center;">
    
```mermaid
graph TD
        USDC((USDC)) --> T((T))
        USDC((USDC)) --> Tbar((T̅))
        style USDC fill:#2196F3,stroke:#333,stroke-width:2px,color:#fff
        style T fill:#4CAF50,stroke:#333,stroke-width:2px,color:#fff
        style Tbar fill:#FF5722,stroke:#333,stroke-width:2px,color:#fff
```
  </div>

<div style="display: flex; justify-content: center;">

```mermaid
graph TD
        T((T)) --> USDC((USDC))
        Tbar((T̅)) --> USDC((USDC))
        style USDC fill:#2196F3,stroke:#333,stroke-width:2px,color:#fff
        style T fill:#4CAF50,stroke:#333,stroke-width:2px,color:#fff
        style Tbar fill:#FF5722,stroke:#333,stroke-width:2px,color:#fff
```

  </div>
