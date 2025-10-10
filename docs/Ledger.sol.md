```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Types.sol";
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

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// Custom ERC20 for positions, with mint/burn restricted to ledger
contract PositionToken is ERC20 {
    address public immutable ledger;
    uint256 public immutable marketId;
    uint256 public immutable positionId;
    bool public immutable isBack;

    constructor(
        string memory name,
        string memory symbol,
        address _ledger,
        uint256 _marketId,
        uint256 _positionId,
        bool _isBack
    ) ERC20(name, symbol) {
        ledger = _ledger;
        marketId = _marketId;
        positionId = _positionId;
        isBack = _isBack;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _spendAllowance(from, ledger, amount);
        _burn(from, amount);
    }
}

interface IPositionToken {
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}

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

    StorageLib.Storage private s;

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

    constructor(address _usdc, address _aUSDC, address _aavePool) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.owner = msg.sender;
        store.usdc = IERC20(_usdc);
        store.aUSDC = IERC20(_aUSDC);
        store.aavePool = IAavePool(_aavePool);
    }

    function registerMarketMaker() external returns (uint256 mmId) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        mmId = store.nextMMId++;
        store.mmIdToAddress[mmId] = msg.sender;
        emit MarketMakerRegistered(msg.sender, mmId);
    }

    function createMarket(string memory name, string memory ticker) external onlyOwner returns (uint256 marketId) {
        marketId = MarketManagementLib.createMarket(name, ticker);
    }

    function createPosition(uint256 marketId, string memory name, string memory ticker) external onlyOwner returns (uint256 positionId) {
        positionId = MarketManagementLib.createPosition(marketId, name, ticker);
    }

    function deposit(uint256 mmId, uint256 amount, uint256 minUSDCDeposited) external returns (uint256 recordedUSDC) {
        recordedUSDC = DepositWithdrawLib.deposit(mmId, amount, minUSDCDeposited);
        emit Deposited(mmId, recordedUSDC);
    }

    function withdraw(uint256 mmId, uint256 amount) external {
        DepositWithdrawLib.withdraw(mmId, amount);
        emit Withdrawn(mmId, amount);
    }

    function withdrawInterest() external onlyOwner {
        DepositWithdrawLib.withdrawInterest(msg.sender);
    }

    function redeemSet(uint256 marketId, uint256[] memory positionIds, uint256 amount, address to) external {
        RedemptionLib.redeemSet(marketId, positionIds, amount, to);
    }

    function processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited
    ) external returns (uint256 recordedUSDC) {
        (recordedUSDC, uint256 freeCollateral, int256 allocatedCapital, int128 newTilt) = TradingLib.processBuy(
            to, marketId, mmId, positionId, isBack, usdcIn, tokensOut, minUSDCDeposited
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
    ) external {
        (uint256 freeCollateral, int256 allocatedCapital, int128 newTilt) = TradingLib.processSell(
            to, marketId, mmId, positionId, isBack, tokensIn, usdcOut
        );
        emit Sold(mmId, marketId, positionId, isBack, tokensIn, usdcOut);
        emit TiltUpdated(mmId, marketId, positionId, freeCollateral, allocatedCapital, newTilt);
    }

    function transferLiquidity(uint256 mmId, address newAddress) external {
        LiquidityLib.transferLiquidity(mmId, newAddress);
        emit LiquidityTransferred(mmId, msg.sender, newAddress);
    }

    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        external
        view
        returns (uint256 freeCollateral, int256 allocatedCapital, int128 tilt)
    {
        return LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
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
        name = store.marketNames[marketId];
        ticker = store.marketTickers[marketId];
    }

    function getPositionDetails(uint256 marketId, uint256 positionId)
        external
        view
        returns (string memory name, string memory ticker, address backToken, address layToken)
    {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = store.positionNames[marketId][positionId];
        ticker = store.positionTickers[marketId][positionId];
        backToken = store.tokenAddresses[marketId][positionId][true];
        layToken = store.tokenAddresses[marketId][positionId][false];
    }
}
```