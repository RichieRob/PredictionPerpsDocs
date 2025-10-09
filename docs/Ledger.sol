// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Libraries.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// Custom ERC20 for positions, with mint/burn restricted to ledger
contract PositionToken is ERC20 {
    address public immutable ledger;

    constructor(string memory name, string memory symbol, address _ledger) ERC20(name, symbol) {
        ledger = _ledger;
    }

    /// @notice Mint tokens (only callable by ledger)
    function mint(address to, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _mint(to, amount);
    }

    /// @notice Burn tokens from an account (only callable by ledger, checks allowance)
    function burnFrom(address from, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _spendAllowance(from, ledger, amount);
        _burn(from, amount);
    }
}

// Interface for PositionToken interactions
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
    using TradingLib for *;

    // === Storage ===
    StorageLib.Storage private s;

    // === Events ===
    event Deposited(address indexed mm, uint256 amount);
    event Withdrawn(address indexed mm, uint256 amount);
    event TiltUpdated(address indexed mm, uint256 marketId, uint256 positionId, int128 newTilt);
    event Bought(address indexed buyer, uint256 marketId, uint256 positionId, bool isBack, uint256 amount);
    event Sold(address indexed seller, uint256 marketId, uint256 positionId, bool isBack, uint256 amount);

    // === Modifiers ===
    modifier onlyOwner() {
        require(msg.sender == StorageLib.getStorage().owner, "Only owner");
        _;
    }

    // === Constructor ===
    constructor(address _usdc, address _aUSDC, address _aavePool) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.owner = msg.sender;
        store.usdc = IERC20(_usdc);
        store.aUSDC = IERC20(_aUSDC);
        store.aavePool = IAavePool(_aavePool);
    }

    // === Admin Operations (Market/Position Creation) ===
    /// @notice Creates a new market
    function createMarket(string memory name, string memory ticker) external onlyOwner returns (uint256 marketId) {
        marketId = MarketManagementLib.createMarket(name, ticker);
    }

    /// @notice Creates a new position in a market
    function createPosition(uint256 marketId, string memory name, string memory ticker) external onlyOwner returns (uint256 positionId) {
        positionId = MarketManagementLib.createPosition(marketId, name, ticker);
    }

    // === Deposit/Withdraw Operations ===
    /// @notice Deposits USDC to market maker's free collateral
    function deposit(uint256 amount) external {
        DepositWithdrawLib.deposit(msg.sender, amount);
        emit Deposited(msg.sender, amount);
    }

    /// @notice Withdraws USDC from market maker's free collateral
    function withdraw(uint256 amount) external {
        DepositWithdrawLib.withdraw(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Withdraws accrued interest to owner
    function withdrawInterest() external onlyOwner {
        DepositWithdrawLib.withdrawInterest(msg.sender);
    }

    // === Trading Operations ===
    /// @notice Buys tokens for a position, depositing USDC
    function processBuy(address to, uint256 marketId, uint256 AMMId, uint256 positionId, bool isBack, uint256 usdcIn, uint256 tokensOut) external {
        TradingLib.processBuy(to, marketId, AMMId, positionId, isBack, usdcIn, tokensOut);
        emit Bought(msg.sender, marketId, positionId, isBack, tokensOut);
    }

    /// @notice Sells tokens for a position, withdrawing USDC
    function processSell(address to, uint256 marketId, uint256 AMMId, uint256 positionId, bool isBack, uint256 tokensIn, uint256 usdcOut) external {
        TradingLib.processSell(to, marketId, AMMId, positionId, isBack, tokensIn, usdcOut);
        emit Sold(msg.sender, marketId, positionId, isBack, tokensIn);
    }

    // === Token Operations ===
    /// @notice Emits q Back tokens for position k
    function emitBack(uint256 marketId, uint256 positionId, uint256 q, address to) external {
        SolvencyLib.ensureSolvency(msg.sender, marketId, positionId, -int128(uint128(q)), 0);
        HeapLib.updateTilt(msg.sender, marketId, positionId, -int128(uint128(q)));
        TokenOpsLib.mintToken(marketId, positionId, true, q, to);
        emit TiltUpdated(msg.sender, marketId, positionId, StorageLib.getStorage().tilt[msg.sender][marketId][positionId]);
    }

    /// @notice Receives q Back tokens for position k (requires approval for burn)
    function receiveBack(uint256 marketId, uint256 positionId, uint256 q) external {
        HeapLib.updateTilt(msg.sender, marketId, positionId, int128(uint128(q)));
        SolvencyLib.deallocateExcess(msg.sender, marketId);
        TokenOpsLib.burnToken(marketId, positionId, true, q, msg.sender);
        emit TiltUpdated(msg.sender, marketId, positionId, StorageLib.getStorage().tilt[msg.sender][marketId][positionId]);
    }

    /// @notice Emits q Lay tokens for position k
    function emitLay(uint256 marketId, uint256 positionId, uint256 q, address to) external {
        SolvencyLib.ensureSolvency(msg.sender, marketId, positionId, int128(uint128(q)), -int128(uint128(q)));
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.marketExposure[msg.sender][marketId] -= q;
        store.mmCapitalization[msg.sender] -= q;
        store.globalCapitalization -= q;
        HeapLib.updateTilt(msg.sender, marketId, positionId, int128(uint128(q)));
        TokenOpsLib.mintToken(marketId, positionId, false, q, to);
        emit TiltUpdated(msg.sender, marketId, positionId, store.tilt[msg.sender][marketId][positionId]);
    }

    /// @notice Receives q Lay tokens for position k (requires approval for burn)
    function receiveLay(uint256 marketId, uint256 positionId, uint256 q) external {
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.marketExposure[msg.sender][marketId] += q;
        store.mmCapitalization[msg.sender] += q;
        store.globalCapitalization += q;
        HeapLib.updateTilt(msg.sender, marketId, positionId, -int128(uint128(q)));
        SolvencyLib.deallocateExcess(msg.sender, marketId);
        TokenOpsLib.burnToken(marketId, positionId, false, q, msg.sender);
        emit TiltUpdated(msg.sender, marketId, positionId, store.tilt[msg.sender][marketId][positionId]);
    }

    // === Getter Functions ===
    /// @notice Returns market maker's capitalization
    function getMMCapitalization(address mm) external view returns (uint256) {
        return StorageLib.getStorage().mmCapitalization[mm];
    }

    /// @notice Returns current interest accrued
    function getInterest() external view returns (uint256) {
        return DepositWithdrawLib.getInterest();
    }

    /// @notice Returns list of all market IDs
    function getMarkets() external view returns (uint256[] memory) {
        return MarketManagementLib.getMarkets();
    }

    /// @notice Returns list of position IDs for a market
    function getMarketPositions(uint256 marketId) external view returns (uint256[] memory) {
        return MarketManagementLib.getMarketPositions(marketId);
    }

    /// @notice Returns market details
    function getMarketDetails(uint256 marketId) external view returns (string memory name, string memory ticker) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = store.marketNames[marketId];
        ticker = store.marketTickers[marketId];
    }

    /// @notice Returns position details
    function getPositionDetails(uint256 marketId, uint256 positionId) external view returns (string memory name, string memory ticker, address backToken, address layToken) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = store.positionNames[marketId][positionId];
        ticker = store.positionTickers[marketId][positionId];
        backToken = store.tokenAddresses[marketId][positionId][true];
        layToken = store.tokenAddresses[marketId][positionId][false];
    }

    // Add new public/external functions here, e.g., settleMarket, updateTiltBatch
}