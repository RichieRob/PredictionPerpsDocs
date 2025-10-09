// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";

library DepositWithdrawLib {
    //region DepositWithdraw
    /// @notice Deposits USDC to MM's freeCollateral, supplies to Aave, updates capitalizations
    /// @param mmId The market maker's ID
    /// @param amount The intended USDC deposit amount
    /// @param minUSDCDeposited The minimum USDC amount to record (optional, 0 if not enforced)
    /// @return recordedAmount The actual aUSDC amount received and recorded
    function deposit(uint256 mmId, uint256 amount, uint256 minUSDCDeposited) internal returns (uint256 recordedAmount) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.usdc.transferFrom(s.mmIdToAddress[mmId], address(this), amount), "Transfer failed");
        s.usdc.approve(address(s.aavePool), amount);

        uint256 aUSDCBefore = s.aUSDC.balanceOf(address(this));
        s.aavePool.supply(address(s.usdc), amount, address(this), 0);
        uint256 aUSDCAfter = s.aUSDC.balanceOf(address(this));
        recordedAmount = aUSDCAfter - aUSDCBefore;

        require(recordedAmount >= minUSDCDeposited, "Deposit below minimum");
        s.freeCollateral[mmId] += recordedAmount;
        s.mmCapitalization[mmId] += recordedAmount;
        s.globalCapitalization += recordedAmount;
    }

    /// @notice Withdraws USDC from MM's freeCollateral, pulls from Aave, updates capitalizations
    /// @param mmId The market maker's ID
    /// @param amount The USDC amount to withdraw
    function withdraw(uint256 mmId, uint256 amount) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        require(s.freeCollateral[mmId] >= amount, "Insufficient free collateral");
        require(s.usdc.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        s.freeCollateral[mmId] -= amount;
        s.mmCapitalization[mmId] -= amount;
        s.globalCapitalization -= amount;
        s.aavePool.withdraw(address(s.usdc), amount, s.mmIdToAddress[mmId]);
    }

    /// @notice Withdraws accrued interest (aUSDC.balance - globalCapitalization) to owner
    function withdrawInterest(address sender) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(sender == s.owner, "Only owner");
        uint256 interest = getInterest();
        if (interest > 0) {
            s.aavePool.withdraw(address(s.usdc), interest, s.owner);
            require(s.usdc.transfer(s.owner, interest), "Transfer failed");
        }
    }

    /// @notice Returns current interest accrued
    function getInterest() internal view returns (uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.aUSDC.balanceOf(address(this)) - s.globalCapitalization;
    }
    //endregion DepositWithdraw
}