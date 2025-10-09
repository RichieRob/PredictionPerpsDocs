// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./HeapLib.sol";

library SolvencyLib {
    //region Solvency
    /// @notice Ensures H_k >= 0 after tilt/exposure change, pulling from freeCollateral if needed
    function ensureSolvency(uint256 mmId, uint256 marketId, uint256 positionId, int128 tiltChange, int128 exposureChange) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mmId, marketId);
        int128 minH_k = minVal + exposureChange;
        if (tiltChange > 0 && positionId == HeapLib.getMinTiltPosition(mmId, marketId)) {
            minH_k = minH_k < tiltChange ? minH_k : tiltChange;
        }
        if (minH_k < 0) {
            StorageLib.Storage storage s = StorageLib.getStorage();
            uint256 shortfall = uint256(-minH_k);
            require(s.freeCollateral[mmId] >= shortfall, "Insufficient free collateral");
            s.freeCollateral[mmId] -= shortfall;
            s.marketExposure[mmId][marketId] += shortfall;
        }
    }

    /// @notice Deallocates excess marketExposure to freeCollateral based on min H_k
    function deallocateExcess(uint256 mmId, uint256 marketId) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mmId, marketId);
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 amount = uint256(int256(s.marketExposure[mmId][marketId]) + minVal);
        if (amount > 0 && amount <= s.marketExposure[mmId][marketId]) {
            s.marketExposure[mmId][marketId] -= amount;
            s.freeCollateral[mmId] += amount;
        }
    }
    //endregion Solvency
}