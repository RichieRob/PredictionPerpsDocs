// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./Types.sol";
import "./PositionToken.sol";

library MarketManagementLib {
    //region MarketManagement
    event MarketCreated(uint256 indexed marketId, string name, string ticker);
    event PositionCreated(uint256 indexed marketId, uint256 indexed positionId, string name, string ticker);

    /// @notice Creates a new market with name and ticker
    function createMarket(string memory name, string memory ticker) internal returns (uint256 marketId) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        marketId = s.nextMarketId++;
        s.marketNames[marketId] = name;
        s.marketTickers[marketId] = ticker;
        s.allMarkets.push(marketId);
        emit MarketCreated(marketId, name, ticker);
    }

    /// @notice Creates a new position in a market with name and ticker, deploys back/lay ERC20 tokens
    function createPosition(uint256 marketId, string memory name, string memory ticker) internal returns (uint256 positionId) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(bytes(s.marketNames[marketId]).length > 0, "Market does not exist");
        positionId = s.nextPositionId[marketId]++;
        s.positionNames[marketId][positionId] = name;
        s.positionTickers[marketId][positionId] = ticker;
        s.marketPositions[marketId].push(positionId);

        // Deploy back token with name "Back [nameOfPosition] [nameOfMarket]" and ticker "B[positionTicker][marketTicker]"
        PositionToken backToken = new PositionToken(
            string.concat("Back ", name, " ", s.marketNames[marketId]),
            string.concat("B", ticker, s.marketTickers[marketId]),
            address(this),
            marketId,
            positionId,
            true
        );
        s.tokenAddresses[marketId][positionId][true] = address(backToken);

        // Deploy lay token with name "Lay [nameOfPosition] [nameOfMarket]" and ticker "L[positionTicker][marketTicker]"
        PositionToken layToken = new PositionToken(
            string.concat("Lay ", name, " ", s.marketNames[marketId]),
            string.concat("L", ticker, s.marketTickers[marketId]),
            address(this),
            marketId,
            positionId,
            false
        );
        s.tokenAddresses[marketId][positionId][false] = address(layToken);

        emit PositionCreated(marketId, positionId, name, ticker);
    }

    /// @notice Returns list of position IDs for a market
    function getMarketPositions(uint256 marketId) internal view returns (uint256[] memory) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.marketPositions[marketId];
    }

    /// @notice Returns list of all market IDs
    function getMarkets() internal view returns (uint256[] memory) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.allMarkets;
    }
    //endregion MarketManagement
}