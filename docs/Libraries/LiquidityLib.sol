// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageLib.sol";

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