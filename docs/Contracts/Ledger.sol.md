```solidity

// attention needed to how we manage the fee. currently its just sent to the ledger and added to deposits


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILedger.sol";
import "./StorageLib.sol";
import "./DepositWithdrawLib.sol";
import "./TokenOpsLib.sol";
import "./SolvencyLib.sol";
import "./HeapLib.sol";
import "./MarketManagementLib.sol";
import "./LiquidityLib.sol";
import "./LedgerLib.sol";
import "./TradingLib.sol";
import "./RedemptionLib.sol";
import "./IPositionToken1155.sol";

contract MarketMakerLedger {
    using DepositWithdrawLib for *;
    using TokenOpsLib for *;
    using SolvencyLib for *;
    using HeapLib for *;
    using MarketManagementLib for *;
    using LiquidityLib for *;
    using LedgerLib for *;
    using TradingLib for *;
    using RedemptionLib for *;

    event Deposited(uint256 indexed mmId, uint256 amount);
    event Withdrawn(uint256 indexed mmId, uint256 amount);
    event TiltUpdated(uint256 indexed mmId, uint256 indexed marketId, uint256 indexed positionId, uint256 freeCollateral, int256 allocatedCapital, int128 newTilt);
    event Bought(uint256 indexed mmId, uint256 indexed marketId, uint256 indexed positionId, bool isBack, uint256 tokensOut, uint256 usdcIn, uint256 recordedUSDC);
    event Sold(uint256 indexed mmId, uint256 indexed marketId, uint256 indexed positionId, bool isBack, uint256 tokensIn, uint256 usdcOut);
    event Redeemed(uint256 indexed marketId, uint256 amount);
    event MarketMakerRegistered(address indexed mmAddress, uint256 mmId);
    event LiquidityTransferred(uint256 indexed mmId, address indexed oldAddress, address indexed newAddress);

    modifier onlyOwner() {
        require(msg.sender == StorageLib.getStorage().owner, "Only owner");
        _;
    }

    constructor(address _usdc, address _aUSDC, address _aavePool, address _positionToken1155, address _permit2) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.owner = msg.sender;
        store.usdc = IERC20(_usdc);
        store.aUSDC = IERC20(_aUSDC);
        store.aavePool = IAavePool(_aavePool);
        store.positionToken1155 = _positionToken1155;
        store.permit2 = _permit2; // may be address(0) if unused
    }

    function registerMarketMaker() external returns (uint256 mmId) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        mmId = store.nextMMId++;
        store.mmIdToAddress[mmId] = msg.sender;
        emit MarketMakerRegistered(msg.sender, mmId);
    }

    // --- market / position management (unchanged) ---
    function createMarket(string memory name, string memory ticker) external onlyOwner returns (uint256 marketId) {
        marketId = MarketManagementLib.createMarket(name, ticker);
    }

    function createPosition(uint256 marketId, string memory name, string memory ticker) external onlyOwner returns (uint256 positionId) {
        positionId = MarketManagementLib.createPosition(marketId, name, ticker);
    }

    // --- owner finance ops ---
    function withdrawInterest() external onlyOwner {
        DepositWithdrawLib.withdrawInterest(msg.sender);
    }

    // --- redemption ---
    function redeemSet(uint256 marketId, uint256[] memory positionIds, uint256 amount, address to) external {
        RedemptionLib.redeemSet(marketId, positionIds, amount, to);
    }

    // --- trading entrypoints ---
    function processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited,
        bool usePermit2,
        bytes calldata permitBlob
    )
        external
        returns (uint256 recordedUSDC, uint256 freeCollateral, int256 allocatedCapital, int128 newTilt)
    {
        (recordedUSDC, freeCollateral, allocatedCapital, newTilt) = TradingLib.processBuy(
            to, marketId, mmId, positionId, isBack, usdcIn, tokensOut, minUSDCDeposited, usePermit2, permitBlob
        );
        emit Bought(mmId, marketId, positionId, isBack, tokensOut, usdcIn, recordedUSDC);
        emit TiltUpdated(mmId, marketId, positionId, freeCollateral, allocatedCapital, newTilt);
    }

    function processSell(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 tokensIn,
        uint256 usdcOut
    )
        external
        returns (uint256 freeCollateral, int256 allocatedCapital, int128 newTilt)
    {
        (freeCollateral, allocatedCapital, newTilt) = TradingLib.processSell(
            to, marketId, mmId, positionId, isBack, tokensIn, usdcOut
        );
        emit Sold(mmId, marketId, positionId, isBack, tokensIn, usdcOut);
        emit TiltUpdated(mmId, marketId, positionId, freeCollateral, allocatedCapital, newTilt);
    }

    // --- views / misc ---
    function transferLiquidity(uint256 mmId, address newAddress) external {
        LiquidityLib.transferLiquidity(mmId, newAddress);
        emit LiquidityTransferred(mmId, msg.sender, newAddress);
    }

    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        external view
        returns (uint256 freeCollateral, int256 allocatedCapital, int128 tilt)
    {
        return LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
    }

    function getAvailableShares(uint256 mmId, uint256 marketId, uint256 positionId)
        external view
        returns (int256)
    {
        (uint256 freeCollateral, int256 allocatedCapital, int128 tilt) =
            LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
        return int256(freeCollateral) + allocatedCapital + int256(tilt);
    }

    function getMinTilt(uint256 mmId, uint256 marketId) external view returns (int128 minTilt, uint256 minPositionId) {
        return LedgerLib.getMinTilt(mmId, marketId);
    }

    function getMarketValue(uint256 marketId) external view returns (uint256) {
        return StorageLib.getStorage().marketValue[marketId];
    }
    function getTotalMarketsValue() external view returns (uint256) {
        return StorageLib.getStorage().TotalMarketsValue;
    }
    function getTotalFreeCollateral() external view returns (uint256) {
        return StorageLib.getStorage().totalFreeCollateral;
    }
    function getTotalValueLocked() external view returns (uint256) {
        return StorageLib.getStorage().totalValueLocked;
    }
    function getMarkets() external view returns (uint256[] memory) {
        return MarketManagementLib.getMarkets();
    }
    function getMarketPositions(uint256 marketId) external view returns (uint256[] memory) {
        return MarketManagementLib.getMarketPositions(marketId);
    }
    function getMarketDetails(uint256 marketId) external view returns (string memory name, string memory ticker) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = IPositionToken1155(store.positionToken1155).getMarketName(marketId);
        ticker = IPositionToken1155(store.positionToken1155).getMarketTicker(marketId);
        return (name, ticker);
    }
    function getPositionDetails(uint256 marketId, uint256 positionId)
        external view
        returns (string memory name, string memory ticker, uint256 backTokenId, uint256 layTokenId)
    {
        StorageLib.Storage storage store = StorageLib.getStorage();
        backTokenId = StorageLib.encodeTokenId(uint64(marketId), uint64(positionId), true);
        layTokenId  = StorageLib.encodeTokenId(uint64(marketId), uint64(positionId), false);
        name = IPositionToken1155(store.positionToken1155).getPositionName(backTokenId);
        ticker = IPositionToken1155(store.positionToken1155).getPositionTicker(backTokenId);
        return (name, ticker, backTokenId, layTokenId);
    }
}
```