// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract P2PLendBorrow {
    uint256 public multiplierPerBlock;

    uint256 public baseRatePerBlock;

    uint256 public constant blocksPerYear = 2102400;

    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock
    );

    constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) {
        baseRatePerBlock = baseRatePerYear / blocksPerYear;
        multiplierPerBlock = multiplierPerYear / blocksPerYear;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }

    // simple lending protocol
    // supply rate

    function getSupplyRate(
        uint256 cash, // total amount of cash in the market
        uint256 borrow, // total amount of borrows in the market
        uint256 reserves, // total amount of reserves in the market
        uint256 reserveFactorMantissa // current reserve factor in the market
    ) external view returns (uint256) {
        // 1. portion of funds available for lending
        uint256 _oneMinusReserveFactor = 10**18 - reserveFactorMantissa;
        // 2. borrow rate
        uint256 _borrowRate = getBorrowRate(cash, borrow, reserves);
        // 3. rateToPool
        uint256 _rateToPool = (_borrowRate * _oneMinusReserveFactor) / 10**18;
        // 4. Supply rate
        uint256 _utilizationRate = utilizationRate(cash, borrow, reserves);
        return (_utilizationRate * _rateToPool) / 10**18;
    }

    function utilizationRate(
        uint256 cash, // total amount of cash in the market
        uint256 borrow, // total amount of borrows in the market
        uint256 reserves // total amount of reserves in the market
    ) public pure returns (uint256) {
        if (borrow == 0) {
            return 0;
        }
        return (borrow * 1e18) / (cash + borrow - reserves);
    }

    // lend (deposit)
    // redeem (withdrawing)

    // p2p lend borrow protocol
    // borrow rate
    function getBorrowRate(
        uint256 cash, // total amount of cash in the market
        uint256 borrow, // total amount of borrows in the market
        uint256 reserves // total amount of reserves in the market
    ) public view returns (uint256) {
        uint256 _utilizationRate = utilizationRate(cash, borrow, reserves);
        return
            ((_utilizationRate * multiplierPerBlock) / 1e18) + baseRatePerBlock;
    }
    // borrow (loan)
    // repay
    // liquidation Call

    // advanced functions
    // flashloan
}

// lend => borrow => repay => redeem
// lend => borrow => liquidationCall
// lend => flashloan
