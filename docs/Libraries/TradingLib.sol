// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";
import "./DepositWithdrawLib.sol";
import "./SolvencyLib.sol";
import "./HeapLib.sol";
import "./TokenOpsLib.sol";
import "./LedgerLib.sol";

library TradingLib {
    //region Trading
    /// @notice Buys q Back or Lay tokens for a position, depositing USDC
    /// @param to Recipient of the tokens
    /// @param marketId The market ID
    /// @param mmId The market maker's ID
    /// @param positionId The position ID
    /// @param isBack True for back tokens, false for lay tokens
    /// @param usdcIn The USDC amount to deposit
    /// @param tokensOut The number of tokens to mint
    /// @param minUSDCDeposited The minimum USDC amount to record from aUSDC
    /// @return recordedUSDC The actual aUSDC amount recorded
    /// @return freeCollateral The MM's free USDC after the operation
    /// @return marketExposure The MM's exposure in the market after the operation
    /// @return newTilt The updated tilt value for the position
    function processBuy(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tokensOut,
        uint256 minUSDCDeposited
    ) internal returns (uint256 recordedUSDC, uint256 freeCollateral, uint256 marketExposure, int128 newTilt) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");

        // Skip deposit if usdcIn is 0 (e.g., for token minting without USDC)
        if (usdcIn > 0) {
            recordedUSDC = DepositWithdrawLib.deposit(mmId, usdcIn, minUSDCDeposited);
        } else {
            recordedUSDC = 0;
        }

        if (isBack) {
            SolvencyLib.ensureSolvency(mmId, marketId, positionId, -int128(uint128(tokensOut)), 0);
            HeapLib.updateTilt(mmId, marketId, positionId, -int128(uint128(tokensOut)));
            TokenOpsLib.mintToken(marketId, positionId, true, tokensOut, to);
        } else {
            SolvencyLib.ensureSolvency(mmId, marketId, positionId, int128(uint128(tokensOut)), -int128(uint128(tokensOut)));
            s.marketExposure[mmId][marketId] -= tokensOut;
            s.mmCapitalization[mmId] -= tokensOut;
            s.globalCapitalization -= tokensOut;
            HeapLib.updateTilt(mmId, marketId, positionId, int128(uint128(tokensOut)));
            TokenOpsLib.mintToken(marketId, positionId, false, tokensOut, to);
        }
        (freeCollateral, marketExposure, newTilt) = LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
    }

    /// @notice Sells q Back or Lay tokens for a position, withdrawing USDC
    /// @param to Recipient of the USDC (zero address if none)
    /// @param marketId The market ID
    /// @param mmId The market maker's ID
    /// @param positionId The position ID
    /// @param isBack True for back tokens, false for lay tokens
    /// @param tokensIn The number of tokens to burn
    /// @param usdcOut The USDC amount to withdraw
    /// @return freeCollateral The MM's free USDC after the operation
    /// @return marketExposure The MM's exposure in the market after the operation
    /// @return newTilt The updated tilt value for the position
    function processSell(
        address to,
        uint256 marketId,
        uint256 mmId,
        uint256 positionId,
        bool isBack,
        uint256 tokensIn,
        uint256 usdcOut
    ) internal returns (uint256 freeCollateral, uint256 marketExposure, int128 newTilt) {
        StorageLib.Storage storage s = StorageLib.getStorage();
        require(s.mmIdToAddress[mmId] == msg.sender, "Invalid MMId");
        if (isBack) {
            HeapLib.updateTilt(mmId, marketId, positionId, int128(uint128(tokensIn)));
            SolvencyLib.deallocateExcess(mmId, marketId);
            TokenOpsLib.burnToken(marketId, positionId, true, tokensIn, msg.sender);
        } else {
            s.marketExposure[mmId][marketId] += tokensIn;
            s.mmCapitalization[mmId] += tokensIn;
            s.globalCapitalization += tokensIn;
            HeapLib.updateTilt(mmId, marketId, positionId, -int128(uint128(tokensIn)));
            SolvencyLib.deallocateExcess(mmId, marketId);
            TokenOpsLib.burnToken(marketId, positionId, false, tokensIn, msg.sender);
        }
        if (usdcOut > 0) {
            DepositWithdrawLib.withdraw(mmId, usdcOut);
        }
        (freeCollateral, marketExposure, newTilt) = LedgerLib.getPositionLiquidity(mmId, marketId, positionId);
    }
    //endregion Trading
}