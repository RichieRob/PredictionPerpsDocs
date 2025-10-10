```solidity

// SPDX-License-Identifier: MIT
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

interface IAavePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
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

    /// @notice Mint tokens (only callable by ledger)
    function mint(
        address to,
        uint256 amount
    ) external {
        require(
            msg.sender == ledger,
            "Only ledger"
        );
        _mint(to, amount);
    }

    /// @notice Burn tokens from an account
    /// (only callable by ledger, checks allowance)
    function burnFrom(
        address from,
        uint256 amount
    ) external {
        require(
            msg.sender == ledger,
            "Only ledger"
        );
        _spendAllowance(
            from,
            ledger,
            amount
        );
        _burn(from, amount);
    }
}

// Interface for PositionToken interactions
interface IPositionToken {
    function mint(
        address to,
        uint256 amount
    ) external;
    function burnFrom(
        address from,
        uint256 amount
    ) external;
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

    // === Storage ===
    StorageLib.Storage private s;

    // === Events ===
    event Deposited(
        uint256 indexed mmId,
        uint256 amount
    );
    event Withdrawn(
        uint256 indexed mmId,
        uint256 amount
    );
    event TiltUpdated(
        uint256 indexed mmId,
        uint256 indexed marketId,
        uint256 indexed positionId,
        uint256 freeCollateral,
        uint256 marketExposure,
        int128 newTilt
    );
    event Bought(
        uint256 indexed mmId,
        uint256 indexed marketId,
        uint256 indexed positionId,
        bool isBack,
        uint256 tokensOut,
        uint256 usdcIn,
        uint256 recordedUSDC
    );
    event Sold(
        uint256 indexed mmId,
        uint256 indexed marketId,
        uint256 indexed positionId,
        bool isBack,
        uint256 tokensIn,
        uint256 usdcOut
    );
    event MarketMakerRegistered(
        address indexed mmAddress,
        uint256 mmId
    );
    event LiquidityTransferred(
        uint256 indexed mmId,
        address indexed oldAddress,
        address indexed newAddress
    );

    // === Modifiers ===
    modifier onlyOwner() {
        require(
            msg.sender == StorageLib.getStorage().owner,
            "Only owner"
        );
        _;
    }

    // === Constructor ===
    constructor(
        address _usdc,
        address _aUSDC,
        address _aavePool
    ) {
        StorageLib.Storage storage store = StorageLib.getStorage();
        store.owner = msg.sender;
        store.usdc = IERC20(_usdc);
        store.aUSDC = IERC20(_aUSDC);
        store.aavePool = IAavePool(_aavePool);
    }

    // === Market Maker Registration ===
    /// @notice Registers a new market maker ID for the caller
    /// @return mmId The assigned market maker ID
    function registerMarketMaker()
        external
        returns (uint256 mmId)
    {
        StorageLib.Storage storage store = StorageLib.getStorage();
        mmId = store.nextMMId++;
        store.mmIdToAddress[mmId] = msg.sender;
        emit MarketMakerRegistered(msg.sender, mmId);
    }

    // === Admin Operations (Market/Position Creation) ===
    /// @notice Creates a new market
    function createMarket(
        string memory name,
        string memory ticker
    )
        external
        onlyOwner
        returns (uint256 marketId)
    {
        marketId = MarketManagementLib.createMarket(
            name,
            ticker
        );
    }

    /// @notice Creates a new position in a market
    function createPosition(
        uint256 marketId,
        string memory name,
        string memory ticker
    )
        external
        onlyOwner
        returns (uint256 positionId)
    {
        positionId = MarketManagementLib.createPosition(
            marketId,
            name,
            ticker
        );
    }

    // === Deposit/Withdraw Operations ===
    /// @notice Deposits USDC to market maker's free collateral
    function deposit(
        uint256 mmId,
        uint256 amount,
        uint256 minUSDCDeposited
    )
        external
        returns (uint256 recordedUSDC)
    {
        recordedUSDC = DepositWithdrawLib.deposit(
            mmId,
            amount,
            minUSDCDeposited
        );
        emit Deposited(mmId, recordedUSDC);
    }

    /// @notice Withdraws USDC from market maker's free collateral
    function withdraw(
        uint256 mmId,
        uint256 amount
    ) external {
        DepositWithdrawLib.withdraw(
            mmId,
            amount
        );
        emit Withdrawn(mmId, amount);
    }

    /// @notice Withdraws accrued interest to owner
    function withdrawInterest()
        external
        onlyOwner
    {
        DepositWithdrawLib.withdrawInterest(msg.sender);
    }

    // === Trading Operations ===
    /// @notice Buys tokens for a position, depositing USDC
    /// Can be used by MM to withdraw position tokens (using 0 USDC)
    /// @return recordedUSDC The actual aUSDC amount recorded
    function processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited
    )
        external
        returns (uint256 recordedUSDC)
    {
        (
            uint256 recordedUSDC,
            uint256 freeCollateral,
            uint256 marketExposure,
            int128 newTilt
        ) = TradingLib.processBuy(
            to,
            marketId,
            mmId,
            positionId,
            isBack,
            usdcIn,
            tokensOut,
            minUSDCDeposited
        );
        emit Bought(
            mmId,
            marketId,
            positionId,
            isBack,
            tokensOut,
            usdcIn,
            recordedUSDC
        );
        emit TiltUpdated(
            mmId,
            marketId,
            positionId,
            freeCollateral,
            marketExposure,
            newTilt
        );
    }

    /// @notice Sells tokens for a position, withdrawing USDC
    /// Can be used by MM to deposit position tokens (using 0 USDC)
    function processSell(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 tokensIn,
        uint256 usdcOut
    ) external {
        (
            uint256 freeCollateral,
            uint256 marketExposure,
            int128 newTilt
        ) = TradingLib.processSell(
            to,
            marketId,
            mmId,
            positionId,
            isBack,
            tokensIn,
            usdcOut
        );
        emit Sold(
            mmId,
            marketId,
            positionId,
            isBack,
            tokensIn,
            usdcOut
        );
        emit TiltUpdated(
            mmId,
            marketId,
            positionId,
            freeCollateral,
            marketExposure,
            newTilt
        );
    }

    // === Liquidity Operations ===
    /// @notice Transfers all liquidity for an MMId to a new address
    function transferLiquidity(
        uint256 mmId,
        address newAddress
    ) external {
        LiquidityLib.transferLiquidity(
            mmId,
            newAddress
        );
        emit LiquidityTransferred(
            mmId,
            msg.sender,
            newAddress
        );
    }

    // === Getter Functions ===
    /// @notice Returns MM's liquidity details for a specific position
    /// @return freeCollateral The MM's free USDC
    /// @return marketExposure The MM's exposure in the market
    /// @return tilt The MM's tilt for the position
    function getPositionLiquidity(
        uint256 mmId,
        uint256 marketId,
        uint256 positionId
    )
        external
        view
        returns (
            uint256 freeCollateral,
            uint256 marketExposure,
            int128 tilt
        )
    {
        return LedgerLib.getPositionLiquidity(
            mmId,
            marketId,
            positionId
        );
    }

    /// @notice Returns the minimum tilt and its position ID for an MM in a market
    /// @return minTilt The minimum (most negative) tilt value
    /// @return minPositionId The position ID with the minimum tilt
    function getMinTilt(
        uint256 mmId,
        uint256 marketId
    )
        external
        view
        returns (
            int128 minTilt,
            uint256 minPositionId
        )
    {
        return LedgerLib.getMinTilt(
            mmId,
            marketId
        );
    }

    /// @notice Returns market maker's capitalization
    function getMMCapitalization(
        uint256 mmId
    )
        external
        view
        returns (uint256)
    {
        return StorageLib.getStorage().mmCapitalization[mmId];
    }

    /// @notice Returns current interest accrued
    function getInterest()
        external
        view
        returns (uint256)
    {
        return DepositWithdrawLib.getInterest();
    }

    /// @notice Returns list of all market IDs
    function getMarkets()
        external
        view
        returns (uint256[] memory)
    {
        return MarketManagementLib.getMarkets();
    }

    /// @notice Returns list of position IDs for a market
    function getMarketPositions(
        uint256 marketId
    )
        external
        view
        returns (uint256[] memory)
    {
        return MarketManagementLib.getMarketPositions(marketId);
    }

    /// @notice Returns market details
    function getMarketDetails(
        uint256 marketId
    )
        external
        view
        returns (
            string memory name,
            string memory ticker
        )
    {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = store.marketNames[marketId];
        ticker = store.marketTickers[marketId];
    }

    /// @notice Returns position details
    function getPositionDetails(
        uint256 marketId,
        uint256 positionId
    )
        external
        view
        returns (
            string memory name,
            string memory ticker,
            address backToken,
            address layToken
        )
    {
        StorageLib.Storage storage store = StorageLib.getStorage();
        name = store.positionNames[marketId][positionId];
        ticker = store.positionTickers[marketId][positionId];
        backToken = store.tokenAddresses[marketId][positionId][true];
        layToken = store.tokenAddresses[marketId][positionId][false];
    }
}
```