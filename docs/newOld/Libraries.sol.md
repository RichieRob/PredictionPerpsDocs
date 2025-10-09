```solidity
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

// === Deposit and Withdraw Operations ===
library DepositWithdrawLib {
    //region DepositWithdraw
    /// @notice Deposits USDC to MM's freeCollateral, supplies to Aave, updates capitalizations
    /// @param mmId The market maker's ID
    /// @param amount The intended USDC deposit amount
    /// @param minUSDCDeposited The minimum USDC amount to record (optional, 0 if not enforced)
    /// @return recordedAmount The actual aUSDC amount received and recorded
    function deposit(uint256 mmId, uint256 amount, uint256 minUSDCDeposited) internal returns (uint256 recordedAmount) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.usdc.transferFrom(s.mmIdToAddress[mmId], address(this), amount), "Transfer failed");
        s.usdc.approve(address(s.aavePool), amount);

        uint256 aUSDCBefore = s.aUSDC.balanceOf(address(this));
        s.aavePool.supply(address(s.usdc), amount, address(this), 0);
        uint256 aUSDCAfter = s.aUSDC.balanceOf(address(this));
        recordedAmount = aUSDCAfter - aUSDCBefore;

        require(recordedAmount >= minUSDCDeposited, "Deposit below minimum");
        s.freeCollateral[mmId] += recordedAmount;
        s.mmCapitalization[mmId] += recordedAmount;
        s.globalCapitalization += recordedAmount;
    }

    /// @notice Withdraws USDC from MM's freeCollateral, pulls from Aave, updates capitalizations
    /// @param mmId The market maker's ID
    /// @param amount The USDC amount to withdraw
    function withdraw(uint256 mmId, uint256 amount) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        require(s.freeCollateral[mmId] >= amount, "Insufficient free collateral");
        require(s.usdc.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        s.freeCollateral[mmId] -= amount;
        s.mmCapitalization[mmId] -= amount;
        s.globalCapitalization -= amount;
        s.aavePool.withdraw(address(s.usdc), amount, s.mmIdToAddress[mmId]);
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
    function ensureSolvency(uint256 mmId, uint256 marketId, uint256 positionId, int128 tiltChange, int128 exposureChange) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mmId, marketId);
        int128 minH_k = minVal + exposureChange;
        if (tiltChange > 0 && positionId == HeapLib.getMinTiltPosition(mmId, marketId)) {
            minH_k = minH_k < tiltChange ? minH_k : tiltChange;
        }
        if (minH_k < 0) {
            StorageLib.Storage storage s = StorageLib.getStorage();
            uint256 shortfall = uint256(-minH_k);
            require(s.freeCollateral[mmId] >= shortfall, "Insufficient free collateral");
            s.freeCollateral[mmId] -= shortfall;
            s.marketExposure[mmId][marketId] += shortfall;
        }
    }

    /// @notice Deallocates excess marketExposure to freeCollateral based on min H_k
    function deallocateExcess(uint256 mmId, uint256 marketId) internal {
        (int128 minVal, ) = HeapLib.getMinTilt(mmId, marketId);
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 amount = uint256(int256(s.marketExposure[mmId][marketId]) + minVal);
        if (amount > 0 && amount <= s.marketExposure[mmId][marketId]) {
            s.marketExposure[mmId][marketId] -= amount;
            s.freeCollateral[mmId] += amount;
        }
    }

    // Add new solvency-related functions here, e.g., bulk solvency checks
    //endregion Solvency
}

// === Heap and Tilt Management ===
library HeapLib {
    //region Tilt Management
    /// @notice Updates tilt and block-min + top-heap for position k by delta
    function updateTilt(uint256 mmId, uint256 marketId, uint256 positionId, int128 delta) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 blockId = positionId / Types.BLOCK_SIZE;
        Types.BlockData storage block = s.blockData[mmId][marketId][blockId];
        int128 newTilt = s.tilt[mmId][marketId][positionId] + delta;
        s.tilt[mmId][marketId][positionId] = newTilt;

        if (positionId != block.minId && newTilt >= block.secondMinVal) return;
        if (positionId != block.minId && newTilt < block.minVal) {
            block.secondMinVal = block.minVal;
            block.minVal = newTilt;
            block.minId = positionId;
            updateTopHeap(mmId, marketId, blockId);
            return;
        }
        if (positionId == block.minId) {
            if (newTilt <= block.minVal) {
                block.minVal = newTilt;
                updateTopHeap(mmId, marketId, blockId);
                return;
            }
            rescanBlock(mmId, marketId, blockId);
        }
    }
    //endregion Tilt Management

    //region Block Scanning
    /// @notice Rescans block to update minId, minVal, secondMinVal
    function rescanBlock(uint256 mmId, uint256 marketId, uint256 blockId) internal {
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
            int128 val = s.tilt[mmId][marketId][k];
            if (val < minVal) {
                secondMinVal = minVal;
                minVal = val;
                minId = k;
            } else if (val < secondMinVal) {
                secondMinVal = val;
            }
        }

        Types.BlockData storage block = s.blockData[mmId][marketId][blockId];
        block.minVal = minVal;
        block.minId = minId;
        block.secondMinVal = secondMinVal;
        updateTopHeap(mmId, marketId, blockId);
    }
    //endregion Block Scanning

    //region Heap Operations
    /// @notice Updates top-heap for blockId (4-ary heap)
    function updateTopHeap(uint256 mmId, uint256 marketId, uint256 blockId) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] storage heap = s.topHeap[mmId][marketId];
        uint256 index = findHeapIndex(heap, blockId);
        int128 newVal = s.blockData[mmId][marketId][blockId].minVal;

        bubbleUp(heap, index, newVal, mmId, marketId);
        bubbleDown(heap, index, newVal, mmId, marketId);
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
    function bubbleUp(uint256[] storage heap, uint256 index, int128 newVal, uint256 mmId, uint256 marketId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (index > 0) {
            uint256 parent = (index - 1) / 4;
            if (s.blockData[mmId][marketId][heap[parent]].minVal <= newVal) break;
            heap[index] = heap[parent];
            index = parent;
        }
    }

    /// @notice Bubbles down the heap to maintain min-heap property
    function bubbleDown(uint256[] storage heap, uint256 index, int128 newVal, uint256 mmId, uint256 marketId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (true) {
            uint256 minChild = index;
            int128 minChildVal = newVal;
            for (uint256 i = 1; i <= 4; i++) {
                uint256 child = index * 4 + i;
                if (child >= heap.length) break;
                if (s.blockData[mmId][marketId][heap[child]].minVal < minChildVal) {
                    minChild = child;
                    minChildVal = s.blockData[mmId][marketId][heap[child]].minVal;
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
    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128, uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] memory heap = s.topHeap[mmId][marketId];
        if (heap.length == 0) return (0, 0);
        uint256 blockId = heap[0];
        Types.BlockData memory block = s.blockData[mmId][marketId][blockId];
        return (block.minVal, block.minId);
    }

    /// @notice Returns positionId of min tilt
    function getMinTiltPosition(uint256 mmId, uint256 marketId) internal view returns (uint256) {
        (, uint256 minId) = getMinTilt(mmId, marketId);
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

// === Liquidity Management ===
library LiquidityLib {
    //region Liquidity
    /// @notice Transfers all liquidity for an MMId to a new address
    /// @param mmId The market maker's ID
    /// @param newAddress The new address to own the MMId
    function transferLiquidity(uint256 mmId, address newAddress) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender || msg.sender == s.owner, "Unauthorized");
        require(newAddress != address(0), "Invalid address");
        s.mmIdToAddress[mmId] = newAddress;
    }
    //endregion Liquidity
}

// === Ledger Reading Operations ===
library LedgerLib {
    //region Ledger
    /// @notice Reads all MM balances across all markets
    /// @param mmId The market maker's ID
    /// @return freeCollateral The MM's free USDC
    /// @return mmCapitalization The MM's total capitalization
    /// @return marketIds Array of market IDs
    /// @return marketExposures Array of exposure values for each market
    /// @return positionIds Array of position IDs for each market
    /// @return tilts Array of tilt arrays for each market's positions
    function readAllBalances(uint256 mmId)
        internal
        view
        returns (
            uint256 freeCollateral,
            uint256 mmCapitalization,
            uint256[] memory marketIds,
            uint256[] memory marketExposures,
            uint256[][] memory positionIds,
            int128[][] memory tilts
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        mmCapitalization = s.mmCapitalization[mmId];
        marketIds = MarketManagementLib.getMarkets();
        marketExposures = new uint256[](marketIds.length);
        positionIds = new uint256[][](marketIds.length);
        tilts = new int128[][](marketIds.length);

        for (uint256 i = 0; i < marketIds.length; i++) {
            uint256 marketId = marketIds[i];
            marketExposures[i] = s.marketExposure[mmId][marketId];
            positionIds[i] = MarketManagementLib.getMarketPositions(marketId);
            tilts[i] = new int128[](positionIds[i].length);
            for (uint256 j = 0; j < positionIds[i].length; j++) {
                tilts[i][j] = s.tilt[mmId][marketId][positionIds[i][j]];
            }
        }
    }

    /// @notice Reads MM's balances for a specific market
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @return freeCollateral The MM's free USDC
    /// @return mmCapitalization The MM's total capitalization
    /// @return marketExposure The MM's exposure in the market
    /// @return positionIds Array of position IDs in the market
    /// @return tilts Array of tilt values for each position
    function readBalances(uint256 mmId, uint256 marketId)
        internal
        view
        returns (
            uint256 freeCollateral,
            uint256 mmCapitalization,
            uint256 marketExposure,
            uint256[] memory positionIds,
            int128[] memory tilts
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        mmCapitalization = s.mmCapitalization[mmId];
        marketExposure = s.marketExposure[mmId][marketId];
        positionIds = MarketManagementLib.getMarketPositions(marketId);
        tilts = new int128[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            tilts[i] = s.tilt[mmId][marketId][positionIds[i]];
        }
    }

    /// @notice Returns MM's free collateral
    /// @param mmId The market maker's ID
    /// @return The MM's free USDC
    function getFreeCollateral(uint256 mmId) internal view returns (uint256) {
        return StorageLib.getStorage().freeCollateral[mmId];
    }

    /// @notice Returns MM's exposure for a market
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @return The MM's exposure in the market
    function getMarketExposure(uint256 mmId, uint256 marketId) internal view returns (uint256) {
        return StorageLib.getStorage().marketExposure[mmId][marketId];
    }

    /// @notice Returns MM's tilt for a position
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @param positionId The position ID
    /// @return The MM's tilt for the position
    function getTilt(uint256 mmId, uint256 marketId, uint256 positionId) internal view returns (int128) {
        return StorageLib.getStorage().tilt[mmId][marketId][positionId];
    }

    /// @notice Returns MM's liquidity details for a specific position
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @param positionId The position ID
    /// @return freeCollateral The MM's free USDC
    /// @return marketExposure The MM's exposure in the market
    /// @return tilt The MM's tilt for the position
    function getPositionLiquidity(uint256 mmId, uint256 marketId, uint256 positionId)
        internal
        view
        returns (
            uint256 freeCollateral,
            uint256 marketExposure,
            int128 tilt
        )
    {
        StorageLib.Storage storage s = StorageLib.getStorage();
        freeCollateral = s.freeCollateral[mmId];
        marketExposure = s.marketExposure[mmId][marketId];
        tilt = s.tilt[mmId][marketId][positionId];
    }

    /// @notice Returns the minimum tilt and its position ID for an MM in a market
    /// @param mmId The market maker's ID
    /// @param marketId The market ID
    /// @return minTilt The minimum (most negative) tilt value
    /// @return minPositionId The position ID with the minimum tilt
    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128 minTilt, uint256 minPositionId) {
        return HeapLib.getMinTilt(mmId, marketId);
    }
    //endregion Ledger
}
```