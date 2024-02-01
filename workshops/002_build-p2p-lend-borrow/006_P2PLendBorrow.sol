// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex; // borrower borrow rate
}

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash minting.
 */
contract FlashMinter is ERC20, IERC3156FlashLender {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public fee; //  1 == 0.01 %.

    /**
     * @param fee_ The percentage of the loan `amount` that needs to be repaid, in addition to `amount`.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 fee_
    ) ERC20(name, symbol) {
        fee = fee_;
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return type(uint256).max - totalSupply();
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency. Must match the address of this contract.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(token == address(this), "FlashMinter: Unsupported currency");
        return _flashFee(token, amount);
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must match the address of this contract.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        require(token == address(this), "FlashMinter: Unsupported currency");
        uint256 fee = _flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                CALLBACK_SUCCESS,
            "FlashMinter: Callback failed"
        );
        uint256 _allowance = allowance(address(receiver), address(this));
        require(
            _allowance >= (amount + fee),
            "FlashMinter: Repay not approved"
        );
        _approve(address(receiver), address(this), _allowance - (amount + fee));
        _burn(address(receiver), amount + fee);
        return true;
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }
}

contract P2PLendBorrow is FlashMinter {
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
    ) FlashMinter(_name, _symbol, 0) {
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

    function maxFlashLoan(address token)
        external
        view
        override
        returns (uint256)
    {
        return getCash();
    }

    function flashFee(address token, uint256 amount)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _flashFee(token, amount);
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

    // advanced functions
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        uint256 fee = _flashFee(address(0), amount);
        uint256 _balancePrior = getCash();
        underlyingToken.transfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, address(0), amount, fee, data) ==
                CALLBACK_SUCCESS,
            "FlashMinter: Callback failed"
        );

        uint256 _balanceAfter = _balancePrior + fee;

        // alternatively transfer borrowed token from flash borrower

        require(
            underlyingToken.transferFrom(
                address(receiver),
                address(this),
                amount + fee
            )
        );

        require(getCash() >= _balanceAfter);

        return true;
    }
}

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {
        NORMAL,
        OTHER
    }

    IERC3156FlashLender lender;

    constructor(IERC3156FlashLender lender_) {
        lender = lender_;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );
        Action action = abi.decode(data, (Action));
        if (action == Action.NORMAL) {
            // do one thing
        } else if (action == Action.OTHER) {
            // do another
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @dev Initiate a flash loan
    function flashBorrow(address token, uint256 amount) public {
        bytes memory data = abi.encode(Action.NORMAL);
        uint256 _allowance = IERC20(token).allowance(
            address(this),
            address(lender)
        );
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
        lender.flashLoan(this, token, amount, data);
    }
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
