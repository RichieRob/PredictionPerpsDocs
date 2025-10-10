// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./DepositWithdrawLib.sol";
import "./SolvencyLib.sol";
import "./HeapLib.sol";
import "./TokenOpsLib.sol";
import "./LedgerLib.sol";

library TradingLib {
    function receiveBackToken(uint256 mmId, uint256 marketId, uint256 positionId, uint256 amount) internal {
        HeapLib.updateTilt(mmId, marketId, positionId, int128(uint128(amount)));
        TokenOpsLib.burnToken(marketId, positionId, true, amount, msg.sender);
        SolvencyLib.deallocateExcess(mmId, marketId);
    }

    function receiveLayToken(uint256 mmId, uint256 marketId, uint256 positionId, uint256 amount) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        s.AllocatedCapital[mmId][marketId] += int256(amount);
        HeapLib.updateTilt(mmId, marketId, positionId, -int128(uint128(amount)));
        TokenOpsLib.burnToken(marketId, positionId, false, amount, msg.sender);
        SolvencyLib.deallocateExcess(mmId, marketId);
    }

    function emitBack(uint256 mmId, uint256 marketId, uint256 positionId, uint256 amount, address to) internal {
        HeapLib.updateTilt(mmId, marketId, positionId, -int128(uint128(amount)));
        TokenOpsLib.mintToken(marketId, positionId, true, amount, to);
        SolvencyLib.ensureSolvency(mmId, marketId);
    }

    function emitLay(uint256 mmId, uint256 marketId, uint256 positionId, uint256 amount, address to) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        s.AllocatedCapital[mmId][marketId] -= int256(amount);
        HeapLib.updateTilt(mmId, marketId, positionId, int128(uint128(amount)));
        TokenOpsLib.mintToken(marketId, positionId, false, amount, to);
        SolvencyLib.ensureSolvency(mmId, marketId);
    }

    function processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited
    ) internal returns (uint256 recordedUSDC, uint256 freeCollateral, int256 allocatedCapital, int128 newTilt) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        if (usdcIn > 0) {
            recordedUSDC = DepositWithdrawLib.deposit(mmId, usdcIn, minUSDCDeposited);
        } else {
            recordedUSDC = 0;
        }
        if (isBack) {
            emitBack(mmId, marketId, positionId, tokensOut, to);
        } else {
            emitLay(mmId, marketId, positionId, tokensOut, to);
        }
        (freeCollateral, allocatedCapital, newTilt) = LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
    }

    function processSell(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 tokensIn,
        uint256 usdcOut
    ) internal returns (uint256 freeCollateral, int256 allocatedCapital, int128 newTilt) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        if (isBack) {
            receiveBackToken(mmId, marketId, positionId, tokensIn);
        } else {
            receiveLayToken(mmId, marketId, positionId, tokensIn);
        }
        if (usdcOut > 0) {
            DepositWithdrawLib.withdraw(mmId, usdcOut);
        }
        (freeCollateral, allocatedCapital, newTilt) = LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
    }
}