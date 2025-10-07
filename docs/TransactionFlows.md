# Transaction Flows and Gas Estimates

## Uniswap v4 PoolManager Path (with Hook + Aave)

1. **User → PoolManager**  
   Swap initiates. *(~25k–35k)*

2. **PoolManager → Hook**  
   `take(USDC, address(this), usdcAmount)`  
   - ERC20 transfer: User → Hook  
   *(~40k–65k cold, ~15k–25k warm)*

3. **Hook → AMM**  
   `requestPositionTokens(...)`  
   *(~8k–12k)*

4. **AMM → Hook**  
   `increaseAMMBalance(...)`  
   *(~8k–12k)*

5. **Hook → Lending Controller**  
   `depositWithInfo(...)`  
   *(~8k–12k)*

6. **Lending Controller → Aave Pool**  
   `supply(USDC, amount, onBehalfOf, referral)`  
   - ERC20 transfer: Hook/LC → Aave  
   - aUSDC minted  
   *(~55k–90k cold, ~40k–60k warm)*

7. **Lending Controller → Vault**  
   `updatePrincipal`  
   *(~15k–25k)*

8. **Vault → Ledger**  
   `recordDepositConfirmation`  
   *(~15k–25k)*

9. **Hook → AMM**  
   `confirmDepositAndMint`  
   *(~8k–12k)*

10. **AMM → Ledger**  
    `mintPositionToken`  
    - ERC20 mint to PoolManager  
    *(~35k–55k cold, ~15k–25k warm)*

11. **Ledger → PoolManager**  
    Accounting + event  
    *(~8k–12k)*

12. **PoolManager → User**  
    ERC20 transfer: PoolManager → User  
    *(~40k–65k cold, ~15k–25k warm)*

**Total (Uniswap path): ~460k–660k gas cold, ~320k–460k warm**


---

## Optimized LFE Path (with Permit + Aave)

1. **User → LFE**  
   `swapAndMint(usdcAmount, marketMakerId, permitSig)`  
   - Inline `permit` signature check  
   *(~30k–50k)*

2. **LFE → Lending Controller**  
   `depositWithInfoAndPermit(...)`  
   - ERC20 transfer: User → LC (via permit + transferFrom)  
   *(~40k–65k cold, ~15k–25k warm)*

3. **Lending Controller → Aave Pool**  
   `supply(USDC, amount, onBehalfOf, referral)`  
   - ERC20 transfer: LC → Aave  
   - aUSDC minted  
   *(~55k–90k cold, ~40k–60k warm)*

4. **Lending Controller → Vault**  
   `updatePrincipal`  
   *(~15k–25k)*

5. **Vault → Ledger**  
   `recordDepositConfirmation`  
   *(~15k–25k)*

6. **Lending Controller → AMM**  
   `confirmDepositAndMint`  
   *(~8k–12k)*

7. **AMM → Ledger**  
   `mintPositionToken`  
   - ERC20 mint direct to User  
   *(~35k–55k cold, ~15k–25k warm)*

8. **Ledger → User**  
   Accounting + event only (no extra transfer)  
   *(~5k–10k)*

**Total (Optimized LFE path): ~280k–460k gas cold, ~210k–320k warm**


---

## Comparison

- **Uniswap v4 Path:** ~460k–660k (cold), ~320k–460k (warm)  
- **Optimized LFE Path:** ~280k–460k (cold), ~210k–320k (warm)  

**Savings:** ~100k–200k gas per transaction, depending on storage state.
