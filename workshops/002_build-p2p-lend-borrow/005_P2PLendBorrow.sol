// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex; // borrower borrow rate
}

contract P2PLendBorrow is ERC20 {
    uint256 public multiplierPerBlock;

    uint256 public baseRatePerBlock;

    uint256 public constant blocksPerYear = 2102400;

    uint256 public totalBorrows;

    uint256 public totalReserves;

    uint256 public initialExchangeRate;

    uint256 accrualBlockNumber;

    // protocol commission, treasury contribution, fees
    uint256 public reserveFactor;

    // Accumulator of total earned interest since the opening of the market
    uint256 public borrowIndex; // marker borrow rate

    // discount for the liquidator for repaying debt of defaultor borrower
    uint256 public liquidationIncentive;

    uint256 public protocolSeizeShare;

    mapping(address => BorrowSnapshot) public accountborrows;

    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock
    );

    IERC20 public underlyingToken;

    PriceOracle public priceOracle;

    constructor(
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _initialExchangeRate,
        uint256 _liquidationIncentive,
        uint256 _protocolSeizeShare,
        address _priceOracle,
        IERC20 _underlyingToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        baseRatePerBlock = _baseRatePerYear / blocksPerYear;
        multiplierPerBlock = _multiplierPerYear / blocksPerYear;
        initialExchangeRate = _initialExchangeRate;
        liquidationIncentive = _liquidationIncentive;
        protocolSeizeShare = _protocolSeizeShare;
        priceOracle = PriceOracle(_priceOracle);
        underlyingToken = _underlyingToken;
        borrowIndex = 1e18;
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

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
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

            return (_cashPlusBorrowMinusReserve * 1e18) / _totalSupply;
        }
    }

    function getBorrowBalance(address _borrower)
        internal
        view
        returns (uint256)
    {
        BorrowSnapshot memory _borrowSnapshot = accountborrows[_borrower];
        if (_borrowSnapshot.principal == 0) {
            return 0;
        }
        // currentBorrowBalance = accountBorrows * market borrow Index / borrower borrow Index
        uint256 principalTimesIndex = _borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / _borrowSnapshot.interestIndex;
    }

    function accrueInterest() public {
        // 1. get the current block number
        uint256 _currentBlockNumber = getBlockNumber();
        uint256 _accrualBlockNumberPrior = accrualBlockNumber;

        if (_currentBlockNumber == _accrualBlockNumberPrior) {
            return;
        }

        // 2. get cash in this protocol
        uint256 _cashPrior = getCash();

        // 3. get the totalborrows
        uint256 _totalBorrowsPrior = totalBorrows;

        // 4. get the reserves
        uint256 _totalReservesPrior = totalReserves;

        // 5. get the borrowIndex
        uint256 _borrowIndexPrior = borrowIndex;

        // 6. calculate borrow interest rate
        uint256 _borrowRate = getBorrowRate(
            _cashPrior,
            _totalBorrowsPrior,
            _totalReservesPrior
        );

        // 7. block delta (difference of block at which last time it was updated and current block)
        uint256 _blockDelta = _currentBlockNumber - _accrualBlockNumberPrior;

        // 8. calculate simple interest = borrowRate * blockDelta
        uint256 _simpleInterest = _borrowRate * _blockDelta;

        // 9. calculating the interest accumulated = simple interest * totalborrows
        uint256 _interestAccumulated = _simpleInterest * _totalBorrowsPrior;

        // update to totalReserves = (reserveFactor * interest accumulated ) + reserves
        totalReserves =
            (reserveFactor * _interestAccumulated) +
            _totalReservesPrior;

        // update the borrows = (interest accumulated  * totalBorrows)
        totalBorrows = _interestAccumulated * totalBorrows;

        // update accrual blocknumber
        accrualBlockNumber = _currentBlockNumber;

        // update borrowIndex = (simpleInterest * borrowIndex) + borrowIndex
        borrowIndex = (_simpleInterest * _borrowIndexPrior) + _borrowIndexPrior;
    }

    // lend (deposit)
    function lend(uint256 _amount, address _receiver) external {
        // update for accruing the interest rate.
        accrueInterest();

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

    function redeem(uint256 _lpTokenAmount) external {
        accrueInterest();

        uint256 _exchangeRate = exchangeRateInternal();

        _burn(msg.sender, _lpTokenAmount);

        /*
         * We calculate the exchange rate and the amount of underlying to be redeemed:
         *  redeemAmount = redeemTokensIn x exchangeRateCurrent
         */
        uint256 _redeemAmount = _lpTokenAmount * _exchangeRate;

        underlyingToken.transfer(msg.sender, _redeemAmount);

        // totalSupply
        // balance of lpToken of msg.sender
        // cash balance of protocol
    }

    // borrow (loan)

    function borrow(uint256 _borrowAmount) external {
        accrueInterest();

        // 1. get the total borrowed amount
        uint256 _accountBorrows = getBorrowBalance(msg.sender);
        uint256 _accountBorrowNew = _accountBorrows + _borrowAmount;
        uint256 _totalBorrowsNew = totalBorrows + _borrowAmount;

        // 2. transfer underlying
        underlyingToken.transfer(msg.sender, _borrowAmount);

        // 3. update borrow snapshot
        accountborrows[msg.sender].principal = _accountBorrowNew;
        accountborrows[msg.sender].interestIndex = borrowIndex;

        // totalBorrows is updated here
        totalBorrows = _totalBorrowsNew;
    }

    // repay
    function repay(address _borrower, uint256 _repayAmount) public {
        // uint256 _borrowIndex = accountborrows[msg.sender].interestIndex;
        uint256 _accountBorrows = getBorrowBalance(_borrower);
        underlyingToken.transferFrom(msg.sender, address(this), _repayAmount);

        uint256 _accountBorrowNew = _accountBorrows - _repayAmount;
        uint256 _totalBorrowNew = totalBorrows - _repayAmount;

        // 3. update borrow snapshot
        accountborrows[_borrower].principal = _accountBorrowNew;
        accountborrows[_borrower].interestIndex = borrowIndex;

        // totalBorrows is updated here
        totalBorrows = _totalBorrowNew;
    }

    // advanced functions

    // liquidation Call
    function liquidationCall(address _borrower, uint256 _repayAmount) external {
        accrueInterest();
        require(_borrower != msg.sender);

        // 1. calculate amount of collateral tokens to be seize
        // a. borrowed token price in USD from price oracle
        uint256 _priceBorrowedToken = priceOracle.getUnderlyingPrice(
            address(this)
        );
        // b. collateral token price in USD from price oracle
        uint256 _priceCollateralToken = priceOracle.getUnderlyingPrice(
            address(this)
        );
        // c. seizeAmount = _repayAmount * liquidationIncentive * price of Borrowed token / price of collateral token
        // uint256 _seizeAmount = (_repayAmount *
        //     liquidationIncentive *
        //     _priceBorrowedToken) / _priceCollateralToken;
        // d. seizeTokens = _repayAmount * (liquidationIncentive * price of Borrowed token) / (price of collateral token * exchangeRate)
        uint256 _seizeTokens = (_repayAmount *
            liquidationIncentive *
            _priceBorrowedToken) /
            (_priceCollateralToken * exchangeRateInternal());
        // 2. repay borrower's debt repay(_repayAmount)
        repay(msg.sender, _repayAmount);
        // 3. now seize the collateral tokens
        // uint256 _borrowerTokensNew = balanceOf(_borrower) - _seizeTokens;
        uint256 _protocolSeizeToken = _seizeTokens * protocolSeizeShare;
        uint256 _liquidatorSeizeToken = _seizeTokens - _protocolSeizeToken;
        uint256 _protocolSeizeAmount = _protocolSeizeToken *
            exchangeRateInternal();
        uint256 _totalReservesNew = totalReserves + _protocolSeizeAmount;
        // uint256 _liquidatorTokens = balanceOf(msg.sender) +
        //     _liquidatorSeizeToken;
        // a. reduce the amount of borrower's account token
        _burn(_borrower, _seizeTokens);
        // b. increase the amount of liquidator's account tokens
        _mint(msg.sender, _liquidatorSeizeToken);
        totalReserves = _totalReservesNew;
    }

    // flashloan
}

contract PriceOracle {
    mapping(address => uint256) public prices;

    function setUnderlyingPrice(address _lpToken, uint256 _price) external {
        prices[_lpToken] = _price;
    }

    function getUnderlyingPrice(address _lpToken)
        external
        view
        returns (uint256)
    {
        return prices[_lpToken];
    }
}

// lend => borrow => repay => redeem
// lend => borrow => liquidationCall
// lend => flashloan

// Alice => $100 Deposit => Cash with Bank = 100
// Bob => $50 borrow => Borrowed amount = 50
// totalAmount => cash + borrow => 50 + 50 => 100
// utilization is 50%
// borrow interest is 10%
// 60 % (utilization) of 10% (borrow interest) => 6%
