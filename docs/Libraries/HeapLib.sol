// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./Types.sol";
import "./MarketManagementLib.sol";

/// @notice Min-heap over blocks (4-ary heap). Each heap node holds a blockId,
/// and its key is s.blockData[mmId][marketId][blockId].minVal.
/// We maintain the heap when a block's minVal changes.
library HeapLib {
    /*//////////////////////////////////////////////////////////////
                               UPDATE TILT
    //////////////////////////////////////////////////////////////*/

    function updateTilt(uint256 mmId, uint256 marketId, uint256 positionId, int128 delta) internal {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 blockId = positionId / Types.BLOCK_SIZE;
        Types.BlockData storage block_ = s.blockData[mmId][marketId][blockId];

        int128 newTilt = s.tilt[mmId][marketId][positionId] + delta;
        s.tilt[mmId][marketId][positionId] = newTilt;

        // Safer lazy init: treat as new only if not present in heap yet AND fields unset.
        (bool inHeap, ) = _getIndex(s, mmId, marketId, blockId);
        if (!inHeap && block_.minId == 0 && block_.minVal == 0 && block_.secondMinVal == 0) {
            block_.minId = positionId;
            block_.minVal = newTilt;
            block_.secondMinVal = type(int128).max;
            _updateTopHeap(mmId, marketId, blockId);
            return;
        }

        // Fast path: position not the current min, and not better than second best.
        if (positionId != block_.minId && newTilt >= block_.secondMinVal) return;

        if (positionId != block_.minId && newTilt < block_.minVal) {
            // New overall min inside this block.
            block_.secondMinVal = block_.minVal;
            block_.minVal = newTilt;
            block_.minId = positionId;
            _updateTopHeap(mmId, marketId, blockId);
            return;
        }

        if (positionId == block_.minId) {
            // The min position changed. If still min (improved), update; else rescan the block.
            if (newTilt <= block_.minVal) {
                block_.minVal = newTilt;
                _updateTopHeap(mmId, marketId, blockId);
                return;
            }
            _rescanBlock(mmId, marketId, blockId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              BLOCK RESCAN
    //////////////////////////////////////////////////////////////*/

    function _rescanBlock(uint256 mmId, uint256 marketId, uint256 blockId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256 start = blockId * Types.BLOCK_SIZE;
        uint256 endExclusive = start + Types.BLOCK_SIZE;

        uint256[] memory positions = MarketManagementLib.getMarketPositions(marketId);
        if (endExclusive > positions.length) endExclusive = positions.length;

        int128 minVal = type(int128).max;
        int128 secondMinVal = type(int128).max;
        uint256 minId = 0;

        for (uint256 i = start; i < endExclusive; i++) {
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

        Types.BlockData storage block_ = s.blockData[mmId][marketId][blockId];
        block_.minVal = minVal;
        block_.minId = minId;
        block_.secondMinVal = secondMinVal;

        _updateTopHeap(mmId, marketId, blockId);
    }

    /*//////////////////////////////////////////////////////////////
                                HEAP CORE
    //////////////////////////////////////////////////////////////*/

    // index map helpers (store idx+1 so 0 == not present)
    function _getIndex(
        StorageLib.Storage storage s,
        uint256 mmId, uint256 marketId, uint256 blockId
    ) private view returns (bool found, uint256 idx) {
        uint256 v = s.heapIndex[mmId][marketId][blockId];
        if (v == 0) return (false, 0);
        return (true, v - 1);
    }

    function _setIndex(
        StorageLib.Storage storage s,
        uint256 mmId, uint256 marketId, uint256 blockId, uint256 idx
    ) private {
        s.heapIndex[mmId][marketId][blockId] = idx + 1;
    }

    function _place(
        StorageLib.Storage storage s,
        uint256[] storage heap,
        uint256 mmId, uint256 marketId,
        uint256 idx, uint256 blockId
    ) private {
        heap[idx] = blockId;
        _setIndex(s, mmId, marketId, blockId, idx);
    }

    /// @dev Bubble the node with (blockId, val) upward; returns final index.
    function _bubbleUp(
        uint256[] storage heap,
        uint256 index,
        uint256 blockId,
        int128 val,
        uint256 mmId,
        uint256 marketId
    ) private returns (uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (index > 0) {
            uint256 parent = (index - 1) / 4;
            int128 parentVal = s.blockData[mmId][marketId][heap[parent]].minVal;
            if (parentVal <= val) break;
            // move parent down one level and fix its index
            _place(s, heap, mmId, marketId, index, heap[parent]);
            index = parent;
        }
        _place(s, heap, mmId, marketId, index, blockId);
        return index;
    }

    /// @dev Bubble the node with (blockId, val) downward; returns final index.
    function _bubbleDown(
        uint256[] storage heap,
        uint256 index,
        uint256 blockId,
        int128 val,
        uint256 mmId,
        uint256 marketId
    ) private returns (uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        while (true) {
            uint256 minChild = index;
            int128 minChildVal = val; // current node's value

            // 4-ary children: 4*index + 1 .. 4*index + 4
            for (uint256 i = 1; i <= 4; i++) {
                uint256 child = index * 4 + i;
                if (child >= heap.length) break;
                int128 childVal = s.blockData[mmId][marketId][heap[child]].minVal;
                if (childVal < minChildVal) {
                    minChild = child;
                    minChildVal = childVal;
                }
            }
            if (minChild == index) break;

            // move smaller child up
            _place(s, heap, mmId, marketId, index, heap[minChild]);
            index = minChild;
        }
        _place(s, heap, mmId, marketId, index, blockId);
        return index;
    }

    /// @dev Insert or update a block's key in the top heap.
    function _updateTopHeap(uint256 mmId, uint256 marketId, uint256 blockId) private {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] storage heap = s.topHeap[mmId][marketId];
        int128 newVal = s.blockData[mmId][marketId][blockId].minVal;

        (bool found, uint256 idx) = _getIndex(s, mmId, marketId, blockId);

        if (!found) {
            // Insert: append placeholder, then bubble up the new node.
            heap.push(); // increase length
            uint256 newIdx = heap.length - 1;
            _bubbleUp(heap, newIdx, blockId, newVal, mmId, marketId); // sets index via _place
            return;
        }

        // Update: node exists at idx; its key changed to newVal.
        // Try moving up; if it didn't move, try moving down.
        idx = _bubbleUp(heap, idx, blockId, newVal, mmId, marketId);
        _bubbleDown(heap, idx, blockId, newVal, mmId, marketId);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function getMinTilt(uint256 mmId, uint256 marketId) internal view returns (int128, uint256) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        uint256[] memory heap = s.topHeap[mmId][marketId];
        if (heap.length == 0) return (0, 0);
        uint256 blockId = heap[0];
        Types.BlockData memory block_ = s.blockData[mmId][marketId][blockId];
        return (block_.minVal, block_.minId);
    }

    function getMinTiltPosition(uint256 mmId, uint256 marketId) internal view returns (uint256) {
        (, uint256 minId) = getMinTilt(mmId, marketId);
        return minId;
    }
}
