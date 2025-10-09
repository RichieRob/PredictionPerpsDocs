// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./MarketManagementLib.sol";
import "./HeapLib.sol";

library LedgerLib {
    //region Ledger
    /// @notice Returns MM's liquidity details for a specific position
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @param positionId The position ID
    /// @return freeCollateral The MM's free USDC
    /// @return marketExposure The MM's exposure in the market
    /// @return tilt The MM's tilt for the position
    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        internal
        view
        returns (
            uint256 freeCollateral,
            uint256 marketExposure,
            int128 tilt
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        marketExposure = s.marketExposure[mmId][marketId];
        tilt = s.tilt[mmId][marketId][positionId];
    }

    /// @notice Returns the minimum tilt and its position ID for an MM in a market
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @return minTilt The minimum (most negative) tilt value
    /// @return minPositionId The position ID with the minimum tilt
    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128 minTilt, uint256 minPositionId) {
        return HeapLib.getMinTilt(mmId, marketId);
    }
    //endregion Ledger
}