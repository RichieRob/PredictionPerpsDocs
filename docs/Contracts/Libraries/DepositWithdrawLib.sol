// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IPermit2.sol";
import "./TypesPermit.sol";

library DepositWithdrawLib {
    using TypesPermit for *;

    // --- deposit using native EIP-2612 permit and pull from trader ---
    function depositFromTraderWithEIP2612(
        uint256 mmId,
        address trader,
        uint256 amount,
        uint256 minUSDCDeposited,
        TypesPermit.EIP2612Permit memory p
    ) internal returns (uint256 recordedAmount) {
        StorageLib.Storage storage s = StorageLib.getStorage();

        // 1) Permit (trader -> ledger)
        IERC20Permit(address(s.usdc)).permit(
            trader, address(this), p.value, p.deadline, p.v, p.r, p.s
        );

        // 2) Pull USDC from trader
        require(s.usdc.transferFrom(trader, address(this), amount), "USDC pull fail");

        // 3) Supply to Aave
        s.usdc.approve(address(s.aavePool), amount);
        uint256 a0 = s.aUSDC.balanceOf(address(this));
        s.aavePool.supply(address(s.usdc), amount, address(this), 0);
        uint256 a1 = s.aUSDC.balanceOf(address(this));

        recordedAmount = a1 - a0;
        require(recordedAmount >= minUSDCDeposited, "Deposit below minimum");

        // 4) Credit MM collateral
        s.freeCollateral[mmId] += recordedAmount;
        s.totalFreeCollateral += recordedAmount;
        s.totalValueLocked += recordedAmount;
    }

    // --- deposit using Permit2 permitTransferFrom and pull from trader ---
    function depositFromTraderWithPermit2(
        uint256 mmId,
        address trader,
        uint256 amount,
        uint256 minUSDCDeposited,
        bytes calldata permit2Calldata
    ) internal returns (uint256 recordedAmount) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.permit2 != address(0), "Permit2 not set");

        // 1) Permit2 pull to ledger
        IPermit2(s.permit2).permitTransferFrom(
            permit2Calldata, trader, address(this), amount
        );

        // 2) Supply to Aave
        s.usdc.approve(address(s.aavePool), amount);
        uint256 a0 = s.aUSDC.balanceOf(address(this));
        s.aavePool.supply(address(s.usdc), amount, address(this), 0);
        uint256 a1 = s.aUSDC.balanceOf(address(this));

        recordedAmount = a1 - a0;
        require(recordedAmount >= minUSDCDeposited, "Deposit below minimum");

        // 3) Credit MM collateral
        s.freeCollateral[mmId] += recordedAmount;
        s.totalFreeCollateral += recordedAmount;
        s.totalValueLocked += recordedAmount;
    }

    // --- single payout path: withdraw directly to recipient ---
    function withdrawTo(uint256 mmId, uint256 amount, address to) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        require(s.freeCollateral[mmId] >= amount, "Insufficient free collateral");
        require(to != address(0), "Invalid recipient");

        // reduce accounting before external call
        s.freeCollateral[mmId] -= amount;
        s.totalFreeCollateral -= amount;
        s.totalValueLocked -= amount;

        // pull USDC from Aave directly to the trader
        s.aavePool.withdraw(address(s.usdc), amount, to);
    }

    // --- owner interest skim (unchanged, no double-transfer) ---
    function withdrawInterest(address sender) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(sender == s.owner, "Only owner");
        uint256 interest = getInterest();
        if (interest > 0) {
            s.aavePool.withdraw(address(s.usdc), interest, s.owner);
        }
    }

    function getInterest() internal view returns (uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.aUSDC.balanceOf(address(this)) - s.totalValueLocked;
    }
}
