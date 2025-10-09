// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./Types.sol";
import "./MarketManagementLib.sol";

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
}