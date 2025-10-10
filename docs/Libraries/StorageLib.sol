```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Types.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

library StorageLib {
    struct Storage {
        IERC20 usdc;
        IERC20 aUSDC;
        IAavePool aavePool;
        address owner;
        mapping(uint256 => address) mmIdToAddress;
        uint256 nextMMId;
        mapping(uint256 => uint256) freeCollateral;
        mapping(uint256 => mapping(uint256 => int256)) AllocatedCapital;
        mapping(uint256 => mapping(uint256 => int256)) USDCSpent;
        mapping(uint256 => uint256) MarketUSDCSpent;
        mapping(uint256 => uint256) Redemptions;
        mapping(uint256 => uint256) marketValue;
        uint256 TotalMarketsValue;
        uint256 totalFreeCollateral;
        uint256 totalValueLocked;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => int128))) tilt;
        mapping(uint256 => mapping(uint256 => mapping(bool => address))) tokenAddresses;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Types.BlockData))) blockData;
        mapping(uint256 => mapping(uint256 => uint256[])) topHeap;
        uint256 nextMarketId;
        uint256[] allMarkets;
        mapping(uint256 => string) marketNames;
        mapping(uint256 => string) marketTickers;
        mapping(uint256 => uint256) nextPositionId;
        mapping(uint256 => uint256[]) marketPositions;
        mapping(uint256 => mapping(uint256 => string)) positionNames;
        mapping(uint256 => mapping(uint256 => string)) positionTickers;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = keccak256("MarketMakerLedger.storage");
        assembly {
            s.slot := position
        }
    }
}
```