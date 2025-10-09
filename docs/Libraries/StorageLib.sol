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
        uint256 globalCapitalization; // Sum of all mmCapitalization
        mapping(uint256 => address) mmIdToAddress; // MMId -> MM address
        uint256 nextMMId; // Next available MMId
        mapping(uint256 => uint256) freeCollateral; // MMId -> free USDC
        mapping(uint256 => mapping(uint256 => uint256)) marketExposure; // MMId -> market_id -> USDC
        mapping(uint256 => mapping(uint256 => mapping(uint256 => int128))) tilt; // MMId -> market_id -> position_id -> tilt
        mapping(uint256 => uint256) mmCapitalization; // MMId -> freeCollateral + sum(marketExposure)
        mapping(uint256 => mapping(uint256 => mapping(bool => address))) tokenAddresses; // market_id -> position_id -> isBack -> token address
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Types.BlockData))) blockData; // MMId -> market_id -> block_id -> BlockData
        mapping(uint256 => mapping(uint256 => uint256[])) topHeap; // MMId -> market_id -> heap of block indices
        uint256 nextMarketId;
        uint256[] allMarkets;
        mapping(uint256 => string) marketNames;
        mapping(uint256 => string) marketTickers;
        mapping(uint256 => uint256) nextPositionId; // marketId -> next positionId
        mapping(uint256 => uint256[]) marketPositions; // marketId -> list of positionIds
        mapping(uint256 => mapping(uint256 => string)) positionNames; // marketId -> positionId -> name
        mapping(uint256 => mapping(uint256 => string)) positionTickers; // marketId -> positionId -> ticker
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = keccak256("MarketMakerLedger.storage");
        assembly {
            s.slot := position
        }
    }
}