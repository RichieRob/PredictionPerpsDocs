```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LMSRMarketMaker.sol";

/// @title LMSRInitLib
/// @notice Library for market initialization in LMSRMarketMaker.
library LMSRInitLib {
    /// @notice Internal implementation to initialize a market.
    /// @dev Sets up per-market state, listings, and priors. Validates inputs and ensures no re-initialization.
    function initMarketInternal(
        LMSRMarketMaker self,
        uint256 _marketId,
        uint256 _mmId,
        uint256 _numInitial,
        uint256[] memory initialLedgerIds,
        int256[] memory initialR,
        int256 _b,
        int256 reserve0,
        bool _isExpanding
    ) internal {
        require(!self.initialized[_marketId], "already initialized");
        // Ensure at least one initial position (for valid LMSR denom/prices) and cap to prevent gas exhaustion in loop; 4096 is a safe power-of-2 limit.
        require(_numInitial > 0 && _numInitial <= 4096, "bad n");
        require(_b > 0, "b=0");
        require(initialLedgerIds.length == _numInitial, "ids len");
        require(initialR.length == _numInitial, "priors len");

        self.b[_marketId] = _b;
        self.mmId[_marketId] = _mmId;

        // Init global factor
        self.G[_marketId] = int256(LMSRMarketMaker.WAD);

        // Load priors + map listings
        // Initialize neutral state: U_all=0, u_i=0 => G=1, R_i=1, S=n
        self.R[_marketId] = new int256[](_numInitial);
        int256 sum = 0;
        for (uint256 i = 0; i < _numInitial; i++) {
            uint256 lid = initialLedgerIds[i];
            int256 ri = initialR[i];
            require(ri > 0, "prior <= 0");
            require(self.slotOf[_marketId][lid] == 0, "dup id");

            // Strong sanity-check existence in ledger
            require(self.ledger.positionExists(_marketId, lid), "ledger: position !exists");

            self.R[_marketId][i] = ri;
            sum += ri;

            self.slotOf[_marketId][lid] = i + 1;          // store 1-based
            self.ledgerIdOfSlot[_marketId][i] = lid;

            emit LMSRMarketMaker.PositionListed(lid, i, ri);
        }
        self.S_tradables[_marketId] = sum;

        if (_isExpanding) {
            require(reserve0 > 0, "reserve0=0 expanding");
            self.R_reserve[_marketId] = reserve0;
        } else {
            require(reserve0 == 0, "reserve0!=0 fixed");
            self.R_reserve[_marketId] = 0;
        }

        self.numOutcomes[_marketId] = _numInitial;
        self.isExpanding[_marketId] = _isExpanding;

        self.initialized[_marketId] = true;
    }
}

```