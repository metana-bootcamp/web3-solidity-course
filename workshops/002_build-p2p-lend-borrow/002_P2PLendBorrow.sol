// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract P2PLendBorrow is ERC20 {
    uint256 public multiplierPerBlock;

    uint256 public baseRatePerBlock;

    uint256 public constant blocksPerYear = 2102400;

    uint256 public totalBorrows;

    uint256 public totalReserves;

    uint256 public initialExchangeRate;

    uint256 public reserveFactor;

    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock
    );

    IERC20 public underlyingToken;

    constructor(
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _initialExchangeRate,
        IERC20 _underlyingToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        baseRatePerBlock = _baseRatePerYear / blocksPerYear;
        multiplierPerBlock = _multiplierPerYear / blocksPerYear;
        initialExchangeRate = _initialExchangeRate;
        underlyingToken = _underlyingToken;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }

    // simple lending protocol
    // supply rate

    function getSupplyRate(
        uint256 _cash, // total amount of cash in the market
        uint256 _borrow, // total amount of borrows in the market
        uint256 _reserves, // total amount of reserves in the market
        uint256 _reserveFactorMantissa // current reserve factor in the market
    ) external view returns (uint256) {
        // 1. portion of funds available for lending
        uint256 _oneMinusReserveFactor = 10**18 - _reserveFactorMantissa;
        // 2. borrow rate
        uint256 _borrowRate = getBorrowRate(_cash, _borrow, _reserves);
        // 3. rateToPool
        uint256 _rateToPool = (_borrowRate * _oneMinusReserveFactor) / 10**18;
        // 4. Supply rate
        uint256 _utilizationRate = utilizationRate(_cash, _borrow, _reserves);
        return (_utilizationRate * _rateToPool) / 10**18;
    }

    function utilizationRate(
        uint256 _cash, // total amount of cash in the market
        uint256 _borrow, // total amount of borrows in the market
        uint256 _reserves // total amount of reserves in the market
    ) public pure returns (uint256) {
        if (_borrow == 0) {
            return 0;
        }
        return (_borrow * 1e18) / (_cash + _borrow - _reserves);
    }

    // p2p lend borrow protocol
    // borrow rate
    function getBorrowRate(
        uint256 _cash, // total amount of cash in the market
        uint256 _borrow, // total amount of borrows in the market
        uint256 _reserves // total amount of reserves in the market
    ) public view returns (uint256) {
        uint256 _utilizationRate = utilizationRate(_cash, _borrow, _reserves);
        return
            ((_utilizationRate * multiplierPerBlock) / 1e18) + baseRatePerBlock;
    }

    function getCash() public view returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    function exchangeRateInternal() internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        /**
         * exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
         */

        if (_totalSupply == 0) {
            return initialExchangeRate;
        } else {
            uint256 _totalCash = getCash();
            uint256 _cashPlusBorrowMinusReserve = _totalCash +
                totalBorrows -
                totalReserves;

            // calculate interest rate => _cashPlusBorrowMinusReserve and totalSupply
            // mantissa and exponent

            return (_cashPlusBorrowMinusReserve * 1e18) /
                _totalSupply;
        }
    }

    function accrueInterest() external returns (uint256) {
        // 1. get the current block number
        // 2. get cash in this protocol
        // 3. get the totalborrows
        // 4. get the reserves
        // 5. get the borrowIndex
        // 6. calculate borrow interest rate
        // 7. block delta (difference of block at which last time it was updated and current block)
        // 8. calculate simple interest = borrowRate * blockDelta
        // 9. calculating the interest accumulated = simple interest * totalborrows 
        // update to totalReserves = (reserveFactor * interest accumulated ) + reserves
        // update the borrows = (interest accumulated  * totalBorrows)
        // update borrowIndex = (simpleInterest * borrowIndex) + borrowIndex
    }

    // lend (deposit)
    function lend(uint256 _amount, address _receiver) external {
        // update for accruing the interest rate.

        // logic for calculating lpTokens to get minted against _amount of underlying tokens
        // 1. calculate exhange rate between underlying token and lp token
        uint256 _exchangeRateStored = exchangeRateInternal();

        underlyingToken.transferFrom(msg.sender, address(this), _amount);

        // 2. calculate mint token amount
        uint256 _mintTokenAmount = _amount / _exchangeRateStored;

        // mint lp Token
        _mint(_receiver, _mintTokenAmount);
        // total supply of lpToken token will increase
        // balance of underlying token will increase
    }

    // redeem (withdrawing / taking back collateral)

    // borrow (loan)

    function borrow() external {
        // totalBorrows is updated here
        // borrowIndex is updated here 
    }
    // repay
    // liquidation Call

    // advanced functions
    // flashloan
}

// lend => borrow => repay => redeem
// lend => borrow => liquidationCall
// lend => flashloan
