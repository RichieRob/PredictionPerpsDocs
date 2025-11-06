```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./Types.sol";
import "./IPositionToken1155.sol";

library MarketManagementLib {
    event MarketCreated(uint256 indexed marketId, string name, string ticker);
    event PositionCreated(uint256 indexed marketId, uint256 indexed positionId, string name, string ticker);
    event SyntheticLiquidityCreated(uint256 indexed marketId, uint256 amount, uint256 dmmId);
    event PositionSplitFromOther(uint256 indexed marketId, uint256 indexed newPositionId);


    function createMarket(string memory name, string memory ticker, uint256 dmmId, uint256 iscAmount, bool isExpanding) internal returns (uint256 marketId) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        marketId = s.nextMarketId++;
        s.allMarkets.push(marketId);
        IPositionToken1155(s.positionToken1155).setMarketMetadata(marketId, name, ticker);
        s.marketToDMM[marketId] = dmmId;
        s.syntheticCollateral[marketId] = iscAmount;
        emit MarketCreated(marketId, name, ticker);
        emit SyntheticLiquidityCreated(marketId, iscAmount, dmmId);
        s.isExpanding[marketId] = isExpanding;
    }

    function createPosition(uint256 marketId, string memory name, string memory ticker) internal returns (uint256 positionId) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.positionToken1155 != address(0), "Position token not set");
        positionId = s.nextPositionId[marketId]++;
        s.marketPositions[marketId].push(positionId);
        uint256 backTokenId = StorageLib.encodeTokenId(uint64(marketId), uint64(positionId), true);
        uint256 layTokenId = StorageLib.encodeTokenId(uint64(marketId), uint64(positionId), false);
        IPositionToken1155(s.positionToken1155).setPositionMetadata(
            backTokenId,
            string.concat("Back ", name),
            string.concat("B", ticker)
        );
        IPositionToken1155(s.positionToken1155).setPositionMetadata(
            layTokenId,
            string.concat("Lay ", name),
            string.concat("L", ticker)
        );
        emit PositionCreated(marketId, positionId, name, ticker);
    }

    library PositionListingLib {

    function splitFromOther(uint256 marketId, string memory name, string memory ticker) internal returns (uint256 newPositionId) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.isExpanding[marketId], "Not expanding market");
        newPositionId = MarketManagementLib.createPosition(marketId, name, ticker);
        // No MM iteration: Lazy init on first interaction (tilt defaults to 0; heaps include on update/rescan)
        emit PositionSplitFromOther(marketId, newPositionId);
    }
}

    function getMarketPositions(uint256 marketId) internal view returns (uint256[] memory) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.marketPositions[marketId];
    }

    function getMarkets() internal view returns (uint256[] memory) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.allMarkets;
    }

    function isDMM(uint256 mmId, uint256 marketId) internal view returns (bool) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.marketToDMM[marketId] == mmId;
    }
}
```