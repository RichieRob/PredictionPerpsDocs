```solidity
// SPDX-License-License-Identifier: MIT
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
        address positionToken1155;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Types.BlockData))) blockData;
        mapping(uint256 => mapping(uint256 => uint256[])) topHeap;
        uint256 nextMarketId;
        uint256[] allMarkets;
        mapping(uint256 => uint256) nextPositionId;
        mapping(uint256 => uint256[]) marketPositions;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = keccak256("MarketMakerLedger.storage");
        assembly {
            s.slot := position
        }
    }

    function encodeTokenId(uint64 marketId, uint64 positionId, bool isBack) internal pure returns (uint256) {
        return (uint256(marketId) << 64) | (uint256(positionId) << 1) | (isBack ? 1 : 0);
    }

    function decodeTokenId(uint256 tokenId) internal pure returns (Types.TokenData memory) {
        return Types.TokenData({
            marketId: uint64(tokenId >> 64),
            positionId: uint64((tokenId >> 1) & ((1 << 64) - 1)),
            isBack: (tokenId & 1) == 1
        });
    }
}
```