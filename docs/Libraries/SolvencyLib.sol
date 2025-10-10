```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./HeapLib.sol";
import "./AllocateCapitalLib.sol";

library SolvencyLib {
    function ensureSolvency(uint256 mmId, uint256 marketId) internal {
        (int128 minTilt, ) = HeapLib.getMinTilt(mmId, marketId);
        StorageLib.Storage storage s = StorageLib.getStorage();
        int128 minShares = minTilt + s.AllocatedCapital[mmId][marketId];
        if (minShares < 0) {
            uint256 shortfall = uint256(-minShares);
            AllocateCapitalLib.allocate(mmId, marketId, shortfall);
        }
    }

    function deallocateExcess(uint256 mmId, uint256 marketId) internal {
        (int128 minTilt, ) = HeapLib.getMinTilt(mmId, marketId);
        StorageLib.Storage storage s = StorageLib.getStorage();
        if (s.AllocatedCapital[mmId][marketId] + minTilt > 0) {
            uint256 amount = uint256(s.AllocatedCapital[mmId][marketId] + minTilt);
            AllocateCapitalLib.deallocate(mmId, marketId, amount);
        }
    }
}
```