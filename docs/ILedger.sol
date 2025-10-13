// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILedger {
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
        returns (
            uint256 recordedUSDC,
            uint256 freeCollateral,
            int256 allocatedCapital,
            int128 newTilt
        );

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
        returns (
            uint256 freeCollateral,
            int256 allocatedCapital,
            int128 newTilt
        );
}
