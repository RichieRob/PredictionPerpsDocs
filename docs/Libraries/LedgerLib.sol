```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./MarketManagementLib.sol";
import "./HeapLib.sol";

library LedgerLib {
    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        internal
        view
        returns (
            uint256 freeCollateral,
            int256 allocatedCapital,
            int128 tilt
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        allocatedCapital = s.AllocatedCapital[mmId][marketId];
        tilt = s.tilt[mmId][marketId][positionId];
    }

    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128 minTilt, uint256 minPositionId) {
        return HeapLib.getMinTilt(mmId, marketId);
    }
}
```