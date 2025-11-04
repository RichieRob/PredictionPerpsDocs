# LedgerLib.sol – Refactored Version

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./HeapLib.sol";

library LedgerLib {
    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        internal
        view
        returns (
            uint256 freeCollateral,
            int256 virtualOffset,
            int128 tilt
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        
        // virtualOffset = USDCSpent + layOffset
        int256 virtualOffset = s.USDCSpent[mmId][marketId] + s.layOffset[mmId][marketId];
        
        tilt = s.tilt[mmId][marketId][positionId];
    }

    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128 minTilt, uint256 minPositionId) {
        return HeapLib.getMinTilt(mmId, marketId);
    }
}