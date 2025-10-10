```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./TokenOpsLib.sol";

library RedemptionLib {
    event Redeemed(uint256 indexed marketId, uint256 amount);

    function redeemSet(uint256 marketId, uint256[] memory positionIds, uint256 amount, address to) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.marketValue[marketId] >= amount, "Insufficient market value");
        require(s.aUSDC.balanceOf(address(this)) >= amount, "Insufficient aUSDC balance");

        if (positionIds.length == 0) {
            require(s.marketPositions[marketId].length == 1, "Single position market required");
            uint256 positionId = s.marketPositions[marketId][0];
            TokenOpsLib.burnToken(marketId, positionId, true, amount, msg.sender);
            TokenOpsLib.burnToken(marketId, positionId, false, amount, msg.sender);
        } else {
            require(positionIds.length == s.marketPositions[marketId].length, "Full set of positions required");
            for (uint256 i = 0; i < positionIds.length; i++) {
                TokenOpsLib.burnToken(marketId, positionIds[i], true, amount, msg.sender);
            }
        }

        s.Redemptions[marketId] += amount;
        s.marketValue[marketId] -= amount;
        s.TotalMarketsValue -= amount;
        s.totalValueLocked -= amount;
        s.aavePool.withdraw(address(s.usdc), amount, to);
        emit Redeemed(marketId, amount);
    }
}
```