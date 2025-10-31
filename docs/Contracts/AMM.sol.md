```solidity 

// attention needed to how we manage the fee. currently its just sent to the ledger and added to deposits

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { PRBMathSD59x18 } from "@prb/math/PRBMathSD59x18.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILedger.sol";

/// @title LMSRMarketMaker (BACK i and true LAY(not-i))
/// @notice LMSR AMM with O(1) updates using global+local decomposition:
///         x_i = U_all + u_i  =>  E_i = exp(x_i/b) = G * R_i
///         Cache: G = exp(U_all/b), R_i = exp(u_i/b), S = sum_i R_i
///         Prices: p_i = R_i / S
///         BACK buy t:     m = b * ln(1 - p + p * e^{ t/b})
///         BACK sell t:    m = b * ln(1 - p + p * e^{-t/b})
///         LAY(not-i) buy: m = b * ln(   p + (1-p) * e^{ t/b})
///         LAY(not-i) sell:m = b * ln(   p + (1-p) * e^{-t/b})
///         State updates use:
///           ΔU_other, ΔU_k  (see mapping below) and
///           Z' = e^{ΔU_other/b}(Z - E_k) + e^{ΔU_k/b} E_k
///         Implemented as:
///           G    *= e^{ΔU_other/b}
///           R_k  *= e^{(ΔU_k - ΔU_other)/b}
///           S    += (R_k_new - R_k_old)
contract LMSRMarketMaker {
    using PRBMathSD59x18 for int256;

    // ---------- Constants ----------
    uint256 public immutable NUM_OUTCOMES;
    uint256 public constant FEE_BPS = 30;          // 0.30%
    uint256 public constant WAD     = 1e18;        // 1e18 fixed

    // ---------- External ----------
    ILedger public immutable ledger;
    IERC20  public immutable usdc;
    uint256 public immutable marketId;
    uint256 public immutable mmId;

    // ---------- LMSR Params ----------
    // b, m, t are in 1e6 (USDC-like).
    int256  public immutable b;                    // > 0, 1e6-scaled

    // ---------- Decomposed State ----------
    // G = exp(U_all / b) (1e18)
    // R[i] = exp(u_i / b) (1e18)
    // S = sum_i R[i] (1e18)
    int256 public G;               // 1e18
    int256 public S;               // 1e18
    int256[] public R;             // 1e18 per outcome

    // ---------- Events ----------
    event Trade(address indexed user, uint256 indexed positionId, bool isBack, uint256 tokens, uint256 usdcAmount, bool isBuy);
    event PriceUpdated(uint256 indexed positionId, uint256 pBackWad);

    // ---------- Constructor ----------
    constructor(
        address _ledger,
        address _usdc,
        uint256 _marketId,
        uint256 _mmId,
        uint256 _numOutcomes,
        int256  _b
    ) {
        require(_ledger != address(0) && _usdc != address(0), "bad addr");
        require(_numOutcomes > 1 && _numOutcomes <= 4096, "bad n");
        require(_b > 0, "b=0");

        ledger     = ILedger(_ledger);
        usdc       = IERC20(_usdc);
        marketId   = _marketId;
        mmId       = _mmId;
        NUM_OUTCOMES = _numOutcomes;
        b          = _b;

        // Initialize neutral state: U_all=0, u_i=0 => G=1, R_i=1, S=n
        G = int256(WAD);
        R = new int256[](_numOutcomes);
        for (uint256 i = 0; i < _numOutcomes; i++) {
            R[i] = int256(WAD);
        }
        S = int256(WAD) * int256(_numOutcomes);
    }

    // ---------- Views ----------
    /// @notice Back price p_i = R_i / S  (1e18)
    function getBackPriceWad(uint256 positionId) public view returns (uint256) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        return uint256((R[positionId] * int256(WAD)) / S);
    }

    /// @notice Lay(not-i) price per unit payout = 1 - p_i  (1e18)
    function getLayPriceWad(uint256 positionId) external view returns (uint256) {
        return WAD - getBackPriceWad(positionId);
    }

    /// @notice Total Z = sum_i E_i = G * S  (1e18)
    function getZ() public view returns (uint256) {
        return uint256((G * S) / int256(WAD));
    }

    // ---------- Core helpers ----------
    /// @dev returns e^{x/b} where x is in 1e6, result in 1e18
    function _exp_ratio_over_b(int256 x) internal view returns (int256 eWad) {
        int256 xWad = (x * int256(WAD)) / b;      // x/b in 1e18
        eWad = PRBMathSD59x18.exp(xWad);          // 1e18
    }

    /// @dev mul/div 1e18 helper: (a * b) / 1e18
    function _wmul(int256 a, int256 b_) internal pure returns (int256) {
        return (a * b_) / int256(WAD);
    }

    // ---------- Quotes ----------
    /// @notice Quote cost (pre-fee, 1e6) for buying t tokens.
    ///         If isBack=true:    m = b ln(1 - p + p e^{+t/b})
    ///         If isBack=false:   m = b ln(  p + (1-p) e^{+t/b})   // true LAY(not-i)
    function quoteBuy(uint256 positionId, bool isBack, uint256 t) public view returns (uint256 mNoFee) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        require(t > 0, "t=0");

        // p = R_i / S (1e18)
        int256 Ri = R[positionId];
        int256 pWad = (Ri * int256(WAD)) / S;

        int256 eTB = _exp_ratio_over_b(int256(uint256(t))); // e^{+t/b}

        int256 termWad;
        if (isBack) {
            // 1 - p + p * e^{t/b}
            termWad = int256(WAD) - pWad + _wmul(pWad, eTB);
        } else {
            // p + (1 - p) * e^{t/b}
            termWad = pWad + _wmul(int256(WAD) - pWad, eTB);
        }

        int256 lnWad = PRBMathSD59x18.ln(termWad);
        int256 mSigned = (b * lnWad) / int256(WAD);
        require(mSigned >= 0, "negative m");
        mNoFee = uint256(mSigned);
    }

    /// @notice Quote proceeds (pre-fee magnitude, 1e6) for selling t tokens.
    ///         If isBack=true:    m = b ln(1 - p + p e^{-t/b})
    ///         If isBack=false:   m = b ln(  p + (1-p) e^{-t/b})
    function quoteSell(uint256 positionId, bool isBack, uint256 t) public view returns (uint256 mNoFeeMagnitude) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        require(t > 0, "t=0");

        int256 Ri = R[positionId];
        int256 pWad = (Ri * int256(WAD)) / S;

        int256 eNegTB = _exp_ratio_over_b(-int256(uint256(t))); // e^{-t/b}

        int256 termWad;
        if (isBack) {
            termWad = int256(WAD) - pWad + _wmul(pWad, eNegTB);
        } else {
            termWad = pWad + _wmul(int256(WAD) - pWad, eNegTB);
        }

        int256 lnWad = PRBMathSD59x18.ln(termWad);
        int256 mSigned = (b * lnWad) / int256(WAD);
        require(mSigned >= 0, "negative m");
        mNoFeeMagnitude = uint256(mSigned);
    }

    /// @notice CLOSED-FORM tokens for exact USDC-in (with fee stripped).
    /// If isBack=true:
    ///   x = exp(m/b);  y = 1 + (x-1)/p;       t =  b * ln(y)
    /// If isBack=false (true LAY):
    ///   x = exp(m/b);  y = (x - p) / (1 - p); t =  b * ln(y)
    function quoteBuyForUSDC(
        uint256 positionId,
        bool isBack,
        uint256 mFinal,
        uint256 /* tMax (ignored) */
    ) public view returns (uint256 tOut) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        require(mFinal > 0, "bad m");

        // strip fee
        uint256 m = (mFinal * 10_000) / (10_000 + FEE_BPS);

        int256 Ri = R[positionId];
        int256 pWad = (Ri * int256(WAD)) / S;
        require(pWad > 0 && pWad < int256(WAD), "bad p");

        int256 mWad = (int256(uint256(m)) * int256(WAD)) / b; // m/b in 1e18
        int256 x    = PRBMathSD59x18.exp(mWad);                // 1e18

        int256 y;
        if (isBack) {
            // y = 1 + (x - 1)/p
            int256 numer = x - int256(WAD);
            y = int256(WAD) + (numer * int256(WAD)) / pWad;
        } else {
            // y = (x - p) / (1 - p)
            int256 denom = int256(WAD) - pWad;
            require(denom > 0, "denom=0");
            int256 numer = x - pWad;
            require(numer > 0, "domain");
            y = (numer * int256(WAD)) / denom;
        }
        require(y >= int256(WAD), "ln domain"); // y >= 1

        int256 lnY = PRBMathSD59x18.ln(y);      // 1e18
        int256 tSigned = (b * lnY) / int256(WAD); // 1e6
        require(tSigned >= 0, "no tokens");

        tOut = uint256(tSigned);
    }

    /// @notice Quote with/without fee wrappers
    function quoteBuyWithFee(uint256 positionId, bool isBack, uint256 t) public view returns (uint256 mFinal) {
        uint256 m = quoteBuy(positionId, isBack, t);
        mFinal = (m * (10_000 + FEE_BPS)) / 10_000;
    }
    function quoteSellWithFee(uint256 positionId, bool isBack, uint256 t) public view returns (uint256 mFinalOut) {
        uint256 m = quoteSell(positionId, isBack, t);
        mFinalOut = (m * (10_000 - FEE_BPS)) / 10_000;
    }

    // ---------- State update (O(1)) ----------
    // Mapping from action -> (ΔU_other, ΔU_k):
    // BACK buy:  (+m, +m - t)
    // BACK sell: (-m, -m + t)
    // LAY  buy:  (+m - t, +m)
    // LAY  sell: (-m + t, -m)
    function _applyUpdate(uint256 positionId, bool isBack, bool isBuy, uint256 t, uint256 mNoFee) internal {
        int256 Ri_old = R[positionId];

        // ΔU values in 1e6
        int256 dU_other;
        int256 dU_k;
        if (isBack && isBuy) {
            dU_other =  int256(uint256(mNoFee));
            dU_k     =  int256(uint256(mNoFee)) - int256(uint256(t));
        } else if (isBack && !isBuy) {
            dU_other = -int256(uint256(mNoFee));
            dU_k     = -int256(uint256(mNoFee)) + int256(uint256(t));
        } else if (!isBack && isBuy) { // LAY(not-i) buy
            dU_other =  int256(uint256(mNoFee)) - int256(uint256(t));
            dU_k     =  int256(uint256(mNoFee));
        } else { // !isBack && !isBuy : LAY(not-i) sell
            dU_other = -int256(uint256(mNoFee)) + int256(uint256(t));
            dU_k     = -int256(uint256(mNoFee));
        }

        // Compute factors
        int256 e_other = _exp_ratio_over_b(dU_other);                    // e^{ΔU_other/b}
        int256 e_local = _exp_ratio_over_b(dU_k - dU_other);             // e^{(ΔU_k-ΔU_other)/b}

        // Update G, R_k, S  (all 1e18)
        G = _wmul(G, e_other);

        int256 Ri_new = _wmul(Ri_old, e_local);
        R[positionId] = Ri_new;

        // S' = S - Ri_old + Ri_new
        S = S - Ri_old + Ri_new;

        // done. Prices p_i = R_i/S update implicitly; Z = G*S
    }

    // ---------- Execution ----------
    /// @notice Buy exact t (BACK i or true LAY(not-i))
    function buy(
        uint256 positionId,
        bool isBack,
        uint256 t,
        uint256 maxUSDCIn,
        bool usePermit2,
        bytes calldata permitBlob
    ) external returns (uint256 mFinal) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        require(t > 0, "t=0");

        uint256 mNoFee = quoteBuy(positionId, isBack, t);
        mFinal = (mNoFee * (10_000 + FEE_BPS)) / 10_000;
        require(mFinal <= maxUSDCIn, "slippage");

        // Pull funds + mint via ledger
        ledger.processBuy(msg.sender, marketId, mmId, positionId, isBack, mFinal, t, 0, usePermit2, permitBlob);

        // O(1) state update
        _applyUpdate(positionId, isBack, true, t, mNoFee);

        emit Trade(msg.sender, positionId, isBack, t, mFinal, true);
        emit PriceUpdated(positionId, getBackPriceWad(positionId));
    }

    /// @notice Buy for exact USDC (inverse closed-form; supports BACK and true LAY)
    function buyForUSDC(
        uint256 positionId,
        bool isBack,
        uint256 usdcIn,
        uint256 tMax,             // unused (ABI compatibility)
        uint256 minTokensOut,
        bool usePermit2,
        bytes calldata permitBlob
    ) external returns (uint256 tOut) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        tOut = quoteBuyForUSDC(positionId, isBack, usdcIn, tMax);
        require(tOut >= minTokensOut && tOut > 0, "slippage");

        // Pull funds + mint via ledger
        ledger.processBuy(msg.sender, marketId, mmId, positionId, isBack, usdcIn, tOut, 0, usePermit2, permitBlob);

        // Pre-fee m needed for ΔU mapping
        uint256 mNoFee = (usdcIn * 10_000) / (10_000 + FEE_BPS);

        // O(1) state update
        _applyUpdate(positionId, isBack, true, tOut, mNoFee);

        emit Trade(msg.sender, positionId, isBack, tOut, usdcIn, true);
        emit PriceUpdated(positionId, getBackPriceWad(positionId));
    }

    /// @notice Sell exact t (BACK i or true LAY(not-i))
    function sell(
        uint256 positionId,
        bool isBack,
        uint256 t,
        uint256 minUSDCOut
    ) external returns (uint256 usdcOut) {
        require(positionId < NUM_OUTCOMES, "bad pos");
        require(t > 0, "t=0");

        uint256 mNoFee = quoteSell(positionId, isBack, t);
        usdcOut = (mNoFee * (10_000 - FEE_BPS)) / 10_000;
        require(usdcOut >= minUSDCOut, "slippage");

        // Burn + pay via ledger
        ledger.processSell(msg.sender, marketId, mmId, positionId, isBack, t, usdcOut);

        // O(1) state update (sell path)
        _applyUpdate(positionId, isBack, false, t, mNoFee);

        emit Trade(msg.sender, positionId, isBack, t, usdcOut, false);
        emit PriceUpdated(positionId, getBackPriceWad(positionId));
    }
}
```