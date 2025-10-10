```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

library Types {
    uint256 constant BLOCK_SIZE = 16;

    struct BlockData {
        uint256 minId; // Position ID of minimum tilt
        int128 minVal; // Minimum tilt value
        int128 secondMinVal; // Second minimum tilt value
    }

    struct TokenData {
        uint64 marketId;
        uint64 positionId;
        bool isBack;
    }
}
```