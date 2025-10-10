```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";

interface IPositionToken {
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}

library TokenOpsLib {
    function mintToken(uint256 marketId, uint256 positionId, bool isBack, uint256 amount, address to) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        address token = s.tokenAddresses[marketId][positionId][isBack];
        require(token != address(0), "Invalid token address");
        IPositionToken(token).mint(to, amount);
    }

    function burnToken(uint256 marketId, uint256 positionId, bool isBack, uint256 amount, address from) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        address token = s.tokenAddresses[marketId][positionId][isBack];
        require(token != address(0), "Invalid token address");
        IPositionToken(token).burnFrom(from, amount);
    }
}
```