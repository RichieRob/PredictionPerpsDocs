# Market Value Tracking Crib Sheet

## Key Counters and Function Updates

1. **freeCollateral[mmId]**
   - **Increases**:
     - `DepositWithdrawLib.deposit`
     - `AllocateCapitalLib.deallocate`
   - **Decreases**:
     - `DepositWithdrawLib.withdraw`
     - `AllocateCapitalLib.allocate`

2. **AllocatedCapital[mmId][marketId]**
   - **Increases**:
     - `TradingLib.receiveLayToken`
     - `AllocateCapitalLib.allocate`
   - **Decreases**:
     - `TradingLib.emitLay`
     - `AllocateCapitalLib.deallocate`

3. **USDCSpent[mmId][marketId]**
   - **Increases**:
     - `AllocateCapitalLib.allocate`
   - **Decreases**:
     - `AllocateCapitalLib.deallocate`

4. **MarketUSDCSpent[marketId]**
   - **Increases**:
     - `AllocateCapitalLib.allocate`
   - **Decreases**:
     - `AllocateCapitalLib.deallocate`

5. **Redemptions[marketId]**
   - **Increases**:
     - `redeemSet`
   - **Decreases**:
     - None

6. **marketValue[marketId]**
   - **Increases**:
     - `AllocateCapitalLib.allocate`
   - **Decreases**:
     - `AllocateCapitalLib.deallocate`
     - `redeemSet`

7. **TotalMarketsValue**
   - **Increases**:
     - `AllocateCapitalLib.allocate`
   - **Decreases**:
     - `AllocateCapitalLib.deallocate`
     - `redeemSet`

8. **totalFreeCollateral**
   - **Increases**:
     - `DepositWithdrawLib.deposit`
     - `AllocateCapitalLib.deallocate`
   - **Decreases**:
     - `DepositWithdrawLib.withdraw`
     - `AllocateCapitalLib.allocate`

9. **totalValueLocked**
   - **Increases**:
     - `DepositWithdrawLib.deposit`
   - **Decreases**:
     - `DepositWithdrawLib.withdraw`
     - `redeemSet`

10. **tilt[mmId][marketId][positionId]**
    - **Increases**:
      - `TradingLib.emitLay`
      - `TradingLib.receiveBackToken`
    - **Decreases**:
      - `TradingLib.emitBack`
      - `TradingLib.receiveLayToken`

11. **getInterest**
    - **Computes**:
      - `DepositWithdrawLib.getInterest` (returns `aUSDC.balanceOf(address(this)) - totalValueLocked`)