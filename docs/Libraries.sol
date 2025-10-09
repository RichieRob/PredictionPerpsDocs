// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// === Types and Constants ===
library Types {
    uint256 constant BLOCK_SIZE = 16;

    struct BlockData {
        uint256 minId; // Position ID of minimum tilt
        int128 minVal; // Minimum tilt value
        int128 secondMinVal; // Second minimum tilt value
    }
}

// === Storage Management ===
library StorageLib {
    struct Storage {
        IERC20 usdc;
        IERC20 aUSDC;
        IAavePool aavePool;
        address owner;
        uint256 globalCapitalization; // Sum of all mmCapitalization
        mapping(address => uint256) freeCollateral; // MM -> free USDC
        mapping(address => mapping(uint256 => uint256)) marketExposure; // MM -> market_id -> USDC
        mapping(address => mapping(uint256 => mapping(uint256 => int128))) tilt; // MM -> market_id -> position_id -> tilt
        mapping(address => uint256) mmCapitalization; // MM -> freeCollateral + sum(marketExposure)
        mapping(uint256 => mapping(uint256 => mapping(bool => address))) tokenAddresses; // market_id -> position_id -> isBack -> token address
        mapping(address => mapping(uint256 => mapping(uint256 => Types.BlockData))) blockData; // MM -> market_id -> block_id -> BlockData
        mapping(address => mapping(uint256 => uint256[])) topHeap; // MM -> market_id -> heap of block indices
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

// === Deposit and Withdraw Operations ===
library DepositWithdrawLib {
    //region DepositWithdraw
    /// @notice Deposits USDC to MM's freeCollateral, supplies to Aave, updates capitalizations
    function deposit(address mm, uint256 amount) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        s.freeCollateral[mm] += amount;
        s.mmCapitalization[mm] += amount;
        s.globalCapitalization += amount;
        require(s.usdc.transferFrom(mm, address(this), amount), "Transfer failed");
        s.usdc.approve(address(s.aavePool), amount);
        s.aavePool.supply(address(s.usdc), amount, address(this), 0);
    }

    /// @notice Withdraws USDC from MM's freeCollateral, pulls from Aave, updates capitalizations
    function withdraw(address mm, uint256 amount) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.freeCollateral[mm] >= amount, "Insufficient free collateral");
        require(s.usdc.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        s.freeCollateral[mm] -= amount;
        s.mmCapitalization[mm] -= amount;
        s.globalCapitalization -= amount;
        s.aavePool.withdraw(address(s.usdc), amount, mm);
    }

    /// @notice Withdraws accrued interest (aUSDC.balance - globalCapitalization) to owner
    function withdrawInterest(address sender) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(sender == s.owner, "Only owner");
        uint256 interest = getInterest();
        if (interest > 0) {
            s.aavePool.withdraw(address(s.usdc), interest, s.owner);
            require(s.usdc.transfer(s.owner, interest), "Transfer failed");
        }
    }

    /// @notice Returns current interest accrued
    function getInterest() internal view returns (uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        return s.aUSDC.balanceOf(address(this)) - s.globalCapitalization;
    }
    //endregion DepositWithdraw
}

// === Token Emission and Burning Operations ===
library TokenOpsLib {
    //region TokenOps
    /// @notice Mints Back or Lay tokens for marketId, positionId, isBack to address to
    function mintToken(uint256 marketId, uint256 positionId, bool isBack, uint256 amount, address to) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        address token = s.tokenAddresses[marketId][positionId][isBack];
        require(token != address(0), "Invalid token address");
        IPositionToken(token).mint(to, amount);
    }

    /// @notice Burns Back or Lay tokens for marketId, positionId, isBack from address from (requires approval)
    function burnToken(uint256 marketId, uint256 positionId, bool isBack, uint256 amount, address from) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        address token = s.tokenAddresses[marketId][positionId][isBack];
        require(token != address(0), "Invalid token address");
        IPositionToken(token).burnFrom(from, amount);
    }

    // Add new token-related functions here, e.g., batch minting, token address updates
    //endregion TokenOps
}

// === Solvency Management ===
library SolvencyLib {
    //region Solvency
    /// @notice Ensures H_k >= 0 after tilt/exposure change, pulling from freeCollateral if needed
    function ensureSolvency(address mm, uint256 marketId, uint256 positionId, int128 tiltChange, int128 exposureChange) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mm, marketId);
        int128 minH_k = minVal + exposureChange;
        if (tiltChange > 0 && positionId == HeapLib.getMinTiltPosition(mm, marketId)) {
            minH_k = minH_k < tiltChange ? minH_k : tiltChange;
        }
        if (minH_k < 0) {
            StorageLib.Storage storage s = StorageLib.getStorage();
            uint256 shortfall = uint256(-minH_k);
            require(s.freeCollateral[mm] >= shortfall, "Insufficient free collateral");
            s.freeCollateral[mm] -= shortfall;
            s.marketExposure[mm][marketId] += shortfall;
        }
    }

    /// @notice Deallocates excess marketExposure to freeCollateral based on min H_k
    function deallocateExcess(address mm, uint256 marketId) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mm, marketId);
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 amount = uint256(int256(s.marketExposure[mm][marketId]) + minVal);
        if (amount > 0 && amount <= s.marketExposure[mm][marketId]) {
            s.marketExposure[mm][marketId] -= amount;
            s.freeCollateral[mm] += amount;
        }
    }

    // Add new solvency-related functions here, e.g., bulk solvency checks
    //endregion Solvency
}

// === Heap and Tilt Management ===
library HeapLib {
    //region Tilt Management
    /// @notice Updates tilt and block-min + top-heap for position k by delta
    function updateTilt(address mm, uint256 marketId, uint256 positionId, int128 delta) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 blockId = positionId / Types.BLOCK_SIZE;
        Types.BlockData storage block = s.blockData[mm][marketId][blockId];
        int128 newTilt = s.tilt[mm][marketId][positionId] + delta;
        s.tilt[mm][marketId][positionId] = newTilt;

        if (positionId != block.minId && newTilt >= block.secondMinVal) return;
        if (positionId != block.minId && newTilt < block.minVal) {
            block.secondMinVal = block.minVal;
            block.minVal = newTilt;
            block.minId = positionId;
            updateTopHeap(mm, marketId, blockId);
            return;
        }
        if (positionId == block.minId) {
            if (newTilt <= block.minVal) {
                block.minVal = newTilt;
                updateTopHeap(mm, marketId, blockId);
                return;
            }
            rescanBlock(mm, marketId, blockId);
        }
    }
    //endregion Tilt Management

    //region Block Scanning
    /// @notice Rescans block to update minId, minVal, secondMinVal
    function rescanBlock(address mm, uint256 marketId, uint256 blockId) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 start = blockId * Types.BLOCK_SIZE;
        uint256 end = start + Types.BLOCK_SIZE;
        uint256[] memory positions = MarketManagementLib.getMarketPositions(marketId);
        if (end > positions.length) end = positions.length;

        int128 minVal = type(int128).max;
        int128 secondMinVal = type(int128).max;
        uint256 minId = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 k = positions[i];
            int128 val = s.tilt[mm][marketId][k];
            if (val < minVal) {
                secondMinVal = minVal;
                minVal = val;
                minId = k;
            } else if (val < secondMinVal) {
                secondMinVal = val;
            }
        }

        Types.BlockData storage block = s.blockData[mm][marketId][blockId];
        block.minVal = minVal;
        block.minId = minId;
        block.secondMinVal = secondMinVal;
        updateTopHeap(mm, marketId, blockId);
    }
    //endregion Block Scanning

    //region Heap Operations
    /// @notice Updates top-heap for blockId (4-ary heap)
    function updateTopHeap(address mm, uint256 marketId, uint256 blockId) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] storage heap = s.topHeap[mm][marketId];
        uint256 index = findHeapIndex(heap, blockId);
        int128 newVal = s.blockData[mm][marketId][blockId].minVal;

        bubbleUp(heap, index, newVal, mm, marketId);
        bubbleDown(heap, index, newVal, mm, marketId);
        heap[index] = blockId;
    }

    /// @notice Finds the index of blockId in the heap
    function findHeapIndex(uint256[] storage heap, uint256 blockId) private view returns (uint256) {
        for (uint256 i = 0; i < heap.length; i++) {
            if (heap[i] == blockId) return i;
        }
        return 0; // Default to root if not found
    }

    /// @notice Bubbles up the heap to maintain min-heap property
    function bubbleUp(uint256[] storage heap, uint256 index, int128 newVal, address mm, uint256 marketId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (index > 0) {
            uint256 parent = (index - 1) / 4;
            if (s.blockData[mm][marketId][heap[parent]].minVal <= newVal) break;
            heap[index] = heap[parent];
            index = parent;
        }
    }

    /// @notice Bubbles down the heap to maintain min-heap property
    function bubbleDown(uint256[] storage heap, uint256 index, int128 newVal, address mm, uint256 marketId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (true) {
            uint256 minChild = index;
            int128 minChildVal = newVal;
            for (uint256 i = 1; i <= 4; i++) {
                uint256 child = index * 4 + i;
                if (child >= heap.length) break;
                if (s.blockData[mm][marketId][heap[child]].minVal < minChildVal) {
                    minChild = child;
                    minChildVal = s.blockData[mm][marketId][heap[child]].minVal;
                }
            }
            if (minChild == index) break;
            heap[index] = heap[minChild];
            index = minChild;
        }
    }
    //endregion Heap Operations

    //region Getters
    /// @notice Returns (minVal, minId) for MM's market
    function getMinTilt(address mm, uint256 marketId) internal view returns (int128, uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] memory heap = s.topHeap[mm][marketId];
        if (heap.length == 0) return (0, 0);
        uint256 blockId = heap[0];
        Types.BlockData memory block = s.blockData[mm][marketId][blockId];
        return (block.minVal, block.minId);
    }

    /// @notice Returns positionId of min tilt
    function getMinTiltPosition(address mm, uint256 marketId) internal view returns (uint256) {
        (, uint256 minId) = getMinTilt(mm, marketId);
        return minId;
    }
    //endregion Getters

    //region Future Extensions
    // Add new heap-related functions here, e.g., bulk tilt updates, heap initialization
    //endregion Future Extensions
}

// === Market and Position Management ===
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
            address(this)
        );
        s.tokenAddresses[marketId][positionId][true] = address(backToken);

        // Deploy lay token with name "Lay [nameOfPosition] [nameOfMarket]" and ticker "L[positionTicker][marketTicker]"
        PositionToken layToken = new PositionToken(
            string.concat("Lay ", name, " ", s.marketNames[marketId]),
            string.concat("L", ticker, s.marketTickers[marketId]),
            address(this)
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

    // Add new market/position functions here, e.g., updateMarketName, settleMarket, deletePosition
    //endregion MarketManagement
}

// === Trading Operations ===
library TradingLib {
    //region Trading
    /// @notice Buys q Back or Lay tokens for a position, depositing USDC
    function processBuy(address to, uint256 marketId, uint256 AMMId, uint256 positionId, bool isBack, uint256 usdcIn, uint256 tokensOut) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(AMMId == msg.sender, "Invalid AMM");
        DepositWithdrawLib.deposit(msg.sender, usdcIn);
        if (isBack) {
            SolvencyLib.ensureSolvency(msg.sender, marketId, positionId, -int128(uint128(tokensOut)), 0);
            HeapLib.updateTilt(msg.sender, marketId, positionId, -int128(uint128(tokensOut)));
            TokenOpsLib.mintToken(marketId, positionId, true, tokensOut, to);
        } else {
            SolvencyLib.ensureSolvency(msg.sender, marketId, positionId, int128(uint128(tokensOut)), -int128(uint128(tokensOut)));
            s.marketExposure[msg.sender][marketId] -= tokensOut;
            s.mmCapitalization[msg.sender] -= tokensOut;
            s.globalCapitalization -= tokensOut;
            HeapLib.updateTilt(msg.sender, marketId, positionId, int128(uint128(tokensOut)));
            TokenOpsLib.mintToken(marketId, positionId, false, tokensOut, to);
        }
    }

    /// @notice Sells q Back or Lay tokens for a position, withdrawing USDC
    function processSell(address to, uint256 marketId, uint256 AMMId, uint256 positionId, bool isBack, uint256 tokensIn, uint256 usdcOut) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(AMMId == msg.sender, "Invalid AMM");
        if (isBack) {
            HeapLib.updateTilt(msg.sender, marketId, positionId, int128(uint128(tokensIn)));
            SolvencyLib.deallocateExcess(msg.sender, marketId);
            TokenOpsLib.burnToken(marketId, positionId, true, tokensIn, msg.sender);
        } else {
            s.marketExposure[msg.sender][marketId] += tokensIn;
            s.mmCapitalization[msg.sender] += tokensIn;
            s.globalCapitalization += tokensIn;
            HeapLib.updateTilt(msg.sender, marketId, positionId, -int128(uint128(tokensIn)));
            SolvencyLib.deallocateExcess(msg.sender, marketId);
            TokenOpsLib.burnToken(marketId, positionId, false, tokensIn, msg.sender);
        }
        DepositWithdrawLib.withdraw(to, usdcOut);
    }

    // Add new trading-related functions here, e.g., batch buy/sell, limit orders
    //endregion Trading
}