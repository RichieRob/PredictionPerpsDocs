```solidity 
// attention needed to how we manage the fee. currently its just sent to the ledger and added to deposits

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { PRBMathSD59x18 } from "@prb/math/PRBMathSD59x18.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILedger.sol";

/// @title LMSRMarketMaker (BACK i and true LAY(not-i)) with Reserve & Expansion
/// @notice O(1) LMSR using global+local decomposition:
///         x_i = U_all + u_i  =>  E_i = exp(x_i/b) = G * R_i
///         Cache: G = exp(U_all/b), R_i = exp(u_i/b)
///         Prices (with reserve): p_i = R_i / (S_tradables + R_reserve)
///         BACK buy t:     m = b * ln(1 - p + p * e^{+t/b})
///         BACK sell t:    m = b * ln(1 - p + p * e^{-t/b})
///         LAY(not-i) buy: m = b * ln(   p + (1-p) * e^{+t/b})
///         LAY(not-i) sell:m = b * ln(   p + (1-p) * e^{-t/b})
///         State updates use:
///           ΔU_rest, ΔU_k  (see mapping below) and
///           Z' = e^{ΔU_rest/b}(Z - E_k) + e^{ΔU_k/b} E_k
///         Implemented as:
///           G     *= e^{ΔU_rest/b}
///           R_k   *= e^{(ΔU_k - ΔU_rest)/b}
///           S_tradables += (R_k_new - R_k_old)
///         NOTE: R_reserve is not touched by trades; only by splitFromReserve().
contract LMSRMarketMaker {
    using PRBMathSD59x18 for int256;

    // ---------- Constants ----------
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
    int256 public G;                  // 1e18

    // Tradable base masses and sums (1e18)
    int256[] public R;                // R[i] for tradables (1e18 each)
    int256 public S_tradables;        // sum_i R[i] (1e18)

    // Non-tradable reserve ("Other") base mass (1e18)
    int256 public R_reserve;          // 1e18; contributes to prices but cannot be traded

    // Tradables count (mutable for expansion)
    uint256 public numOutcomes;       // equals R.length

    // Expanding mode flag
    bool    public isExpanding;

    // ---------- Events ----------
    event Trade(address indexed user, uint256 indexed positionId, bool isBack, uint256 tokens, uint256 usdcAmount, bool isBuy);
    event PriceUpdated(uint256 indexed positionId, uint256 pBackWad);
    event PositionSplitFromReserve(
        uint256 indexed newPositionId,
        uint256 alphaWad,
        int256 reserveBefore,
        int256 reserveAfter,
        int256 Rnew
    );

    // ---------- Constructor ----------
    /// @param _numTradables number of initial tradable outcomes (>=2 recommended)
    /// @param initialR      base masses for tradables (len = _numTradables), 1e18-scaled, each > 0
    /// @param reserve0      initial reserve mass (1e18). Must be 0 if !_isExpanding; >0 if _isExpanding
    constructor(
        address _ledger,
        address _usdc,
        uint256 _marketId,
        uint256 _mmId,
        uint256 _numTradables,
        int256  _b,
        int256[] memory initialR,
        int256  reserve0,
        bool    _isExpanding
    ) {
        require(_ledger != address(0) && _usdc != address(0), "bad addr");
        require(_numTradables > 0 && _numTradables <= 4096, "bad n");
        require(_b > 0, "b=0");
        require(initialR.length == _numTradables, "bad priors len");

        ledger     = ILedger(_ledger);
        usdc       = IERC20(_usdc);
        marketId   = _marketId;
        mmId       = _mmId;
        b          = _b;

        // Initialize G and priors
        G = int256(WAD);

        R = new int256[](_numTradables);
        int256 sum = 0;
        for (uint256 i = 0; i < _numTradables; i++) {
            int256 ri = initialR[i];
            require(ri > 0, "prior <= 0");
            R[i] = ri;
            sum += ri;
        }
        S_tradables = sum;

        if (_isExpanding) {
            require(reserve0 > 0, "reserve0=0 in expanding");
            R_reserve = reserve0;
        } else {
            require(reserve0 == 0, "reserve0!=0 in fixed");
            R_reserve = 0;
        }

        numOutcomes = _numTradables;
        isExpanding = _isExpanding;
    }

    // ---------- Views ----------
    /// @notice Denominator used in prices: S_tradables + R_reserve (1e18)
    function _denom() internal view returns (int256) {
        int256 d = S_tradables + R_reserve;
        require(d > 0, "denom=0");
        return d;
    }

    /// @notice Back price p_i = R_i / (S_tradables + R_reserve) (1e18)
    function getBackPriceWad(uint256 positionId) public view returns (uint256) {
        require(positionId < numOutcomes, "bad pos");
        return uint256((R[positionId] * int256(WAD)) / _denom());
    }

    /// @notice Lay(not-i) price per unit payout = 1 - p_i (1e18)
    function getLayPriceWad(uint256 positionId) external view returns (uint256) {
        return WAD - getBackPriceWad(positionId);
    }

    /// @notice Informational reserve ("Other") price = R_reserve / (S_tradables + R_reserve) (1e18)
    function getReservePriceWad() external view returns (uint256) {
        return uint256((R_reserve * int256(WAD)) / _denom());
    }

    /// @notice Total Z = sum_i E_i = G * (S_tradables + R_reserve)  (1e18)
    function getZ() public view returns (uint256) {
        return uint256((G * _denom()) / int256(WAD));
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
        require(positionId < numOutcomes, "bad pos");
        require(t > 0, "t=0");

        int256 pWad = (R[positionId] * int256(WAD)) / _denom();
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
        require(positionId < numOutcomes, "bad pos");
        require(t > 0, "t=0");

        int256 pWad = (R[positionId] * int256(WAD)) / _denom();
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
        require(positionId < numOutcomes, "bad pos");
        require(mFinal > 0, "bad m");

        // strip fee
        uint256 m = (mFinal * 10_000) / (10_000 + FEE_BPS);

        int256 pWad = (R[positionId] * int256(WAD)) / _denom();
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
    // Mapping from action -> (ΔU_rest, ΔU_k):
    // BACK buy:  (0, +t)
    // BACK sell: (0, -t)
    // LAY  buy:  (+t, 0)   // true LAY(not-k)
    // LAY  sell: (-t, 0)
    function _applyUpdate(uint256 positionId, bool isBack, bool isBuy, uint256 t) internal {
        int256 Ri_old = R[positionId];

        // ΔU values in 1e6
        int256 dU_rest = 0;
        int256 dU_k = 0;
        int256 dt = isBuy ? int256(uint256(t)) : -int256(uint256(t));
        if (isBack) {
            dU_k = dt;
        } else {
            dU_rest = dt;
        }

        // Compute factors
        int256 e_rest  = _exp_ratio_over_b(dU_rest);            // e^{ΔU_rest/b}
        int256 e_local = _exp_ratio_over_b(dU_k - dU_rest);     // e^{(ΔU_k-ΔU_rest)/b}

        // Update G, R_k, S_tradables  (all 1e18)
        G = _wmul(G, e_rest);

        int256 Ri_new = _wmul(Ri_old, e_local);
        R[positionId] = Ri_new;

        // S_tradables' = S_tradables - Ri_old + Ri_new
        S_tradables = S_tradables - Ri_old + Ri_new;

        // Safety for fixed markets: if not expanding, require positive S_tradables
        if (!isExpanding) {
            require(S_tradables > 0, "S underflow");
        }

        // NOTE: R_reserve is not touched by trades; its price moves via the denominator.
    }

    // ---------- Expansion ----------
    /// @notice Split a fraction α (1e18 scale) of the reserve into a new tradable position.
    ///         Maintains price continuity because (S_tradables + R_reserve) stays constant.
    ///         Permission should be enforced by the caller (e.g., market governor).
    function splitFromReserve(uint256 alphaWad) external returns (uint256 newPositionId) {
        require(isExpanding, "not expanding");
        require(alphaWad > 0 && alphaWad <= WAD, "bad alpha");

        int256 before = R_reserve;
        require(before > 0, "reserve empty");

        int256 Rnew = (before * int256(uint256(alphaWad))) / int256(WAD);
        require(Rnew > 0, "tiny split");

        R_reserve = before - Rnew;     // denom unchanged overall
        R.push(Rnew);
        S_tradables += Rnew;

        numOutcomes = R.length;
        newPositionId = numOutcomes - 1;

        emit PositionSplitFromReserve(newPositionId, alphaWad, before, R_reserve, Rnew);
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
        require(positionId < numOutcomes, "bad pos");
        require(t > 0, "t=0");

        uint256 mNoFee = quoteBuy(positionId, isBack, t);
        mFinal = (mNoFee * (10_000 + FEE_BPS)) / 10_000;
        require(mFinal <= maxUSDCIn, "slippage");

        // Pull funds + mint via ledger
        ledger.processBuy(msg.sender, marketId, mmId, positionId, isBack, mFinal, t, 0, usePermit2, permitBlob);

        // O(1) state update
        _applyUpdate(positionId, isBack, true, t);

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
        require(positionId < numOutcomes, "bad pos");
        tOut = quoteBuyForUSDC(positionId, isBack, usdcIn, tMax);
        require(tOut >= minTokensOut && tOut > 0, "slippage");

        // Pull funds + mint via ledger
        ledger.processBuy(msg.sender, marketId, mmId, positionId, isBack, usdcIn, tOut, 0, usePermit2, permitBlob);

        // O(1) state update
        _applyUpdate(positionId, isBack, true, tOut);

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
        require(positionId < numOutcomes, "bad pos");
        require(t > 0, "t=0");

        uint256 mNoFee = quoteSell(positionId, isBack, t);
        usdcOut = (mNoFee * (10_000 - FEE_BPS)) / 10_000;
        require(usdcOut >= minUSDCOut, "slippage");

        // Burn + pay via ledger
        ledger.processSell(msg.sender, marketId, mmId, positionId, isBack, t, usdcOut);

        // O(1) state update (sell path)
        _applyUpdate(positionId, isBack, false, t);

        emit Trade(msg.sender, positionId, isBack, t, usdcOut, false);
        emit PriceUpdated(positionId, getBackPriceWad(positionId));
    }
}

```