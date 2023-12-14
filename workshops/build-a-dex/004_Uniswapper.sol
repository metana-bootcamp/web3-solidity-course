// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol";

// Liquidity Pool Contract
contract Uniswapper is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveTokenA;
    uint256 public reserveTokenB;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    constructor(IERC20 $tokenA, IERC20 $tokenB) ERC20("AB", "AB") {
        tokenA = $tokenA;
        tokenB = $tokenB;
    }

    function getTokenABalance() public view returns (uint256) {
        return tokenA.balanceOf(address(this));
    }

    function getTokenBBalance() public view returns (uint256) {
        return tokenB.balanceOf(address(this));
    }

    function getPriceOfA(uint256 $amountTokenA) public view returns (uint256) {
        return (reserveTokenB * $amountTokenA) / reserveTokenA;
    }

    function getPriceOfB(uint256 $amountTokenB) public view returns (uint256) {
        return (reserveTokenA * $amountTokenB) / reserveTokenB;
    }

    function addLiquidity(uint256 $amountTokenA, uint256 $amountTokenB)
        external
    {
        uint256 _amountTokenAOptimal;
        uint256 _amountTokenBOptimal;
        if (reserveTokenA == 0 && reserveTokenB == 0) {
            _amountTokenAOptimal = $amountTokenA;
            _amountTokenBOptimal = $amountTokenB;
        } else {
            _amountTokenAOptimal = getPriceOfA($amountTokenA);
            _amountTokenBOptimal = getPriceOfB($amountTokenB);
        }
        tokenA.transferFrom(msg.sender, address(this), _amountTokenAOptimal);
        tokenB.transferFrom(msg.sender, address(this), _amountTokenBOptimal);
        uint256 _liquidity;
        // mint logic
        if ( totalSupply() == 0) {
            // calc geometric mean by liquidiity
            _liquidity =
                Math.sqrt(_amountTokenAOptimal * _amountTokenBOptimal) -
                MINIMUM_LIQUIDITY;
        } else {
            uint256 _liquidityA = (_amountTokenAOptimal * totalSupply()) /
                reserveTokenA;
            uint256 _liquidityB = (_amountTokenBOptimal * totalSupply()) /
                reserveTokenB;
            _liquidity = _liquidityA > _liquidityB ? liquidityB : liquidityA;
        }
        _mint(msg.sender, _liquidity);
        reserveTokenA -= _amountTokenAOptimal;
        reserveTokenB += _amountTokenBOptimal;
    }

    // e.g. buy only 100gm  of chips regardless of price
    function swapTokenBForExactTokenA(uint256 $amountTokenA) external {
        uint256 _tokenAReserves = reserveTokenA;
        uint256 _tokenBReserves = reserveTokenB;
        uint256 _tokenBRequired = (1000 * ($amountTokenA * _tokenBReserves)) /
            (997 * (_tokenAReserves - $amountTokenA)); // 0.03%, 99.7
        tokenB.transferFrom(msg.sender, address(this), _tokenBRequired);
        tokenA.transfer(msg.sender, $amountTokenA);
        reserveTokenA -= $amountTokenA;
        reserveTokenB += _tokenBRequired;
    }

    // e.g. spend $1 for any amount of chips
    function swapExactTokenBForTokenA(uint256 _amountTokenB) external {
        uint256 _tokenAReserves = reserveTokenA;
        uint256 _tokenBReserves = reserveTokenB;
        // calculate tokenA amount to be transferred
        uint256 _amountTokenA = (_tokenAReserves * _amountTokenB * 997) /
            ((_tokenBReserves * 1000) + (_amountTokenB * 997));
        tokenB.transferFrom(msg.sender, address(this), _amountTokenB);
        // transfer tokenA to the user
        tokenA.transfer(msg.sender, _amountTokenA);
        reserveTokenA -= _amountTokenA;
        reserveTokenB += _amountTokenB;
    }

    // e.g. sell as many chips as user spent
    function swapTokenAForExactTokenB(uint256 $amountTokenB) external {
        uint256 _tokenAReserves = reserveTokenA;
        uint256 _tokenBReserves = reserveTokenB;
        // calculate amount of tokenA required against _amountTokenB
        uint256 _amountTokenARequired = (_tokenAReserves *
            $amountTokenB *
            1000) / (997 * (_tokenBReserves + $amountTokenB));
        // tokenA is transferred from user to this contract
        tokenA.transferFrom(msg.sender, address(this), _amountTokenARequired);
        // transfer _amountTokenB tokenB to user
        tokenB.transfer(msg.sender, $amountTokenB);
        reserveTokenA += _amountTokenARequired;
        reserveTokenB -= $amountTokenB;
    }

    // e.g. sell chips as per demand regardless of price
    function swapExactTokenAForTokenB(uint256 $amountTokenA) external {
        uint256 _tokenAReserves = reserveTokenA;
        uint256 _tokenBReserves = reserveTokenB;
        // calculate tokenB amount to be transferred
        uint256 _amountTokenB = (_tokenBReserves * $amountTokenA * 997) /
            ((_tokenAReserves * 1000) + (997 * $amountTokenA));
        // _amountTokenA is transfered from user to this contract
        tokenA.transferFrom(msg.sender, address(this), $amountTokenA);
        // transfer tokenB to the user
        tokenB.transfer(msg.sender, _amountTokenB);
        reserveTokenA += $amountTokenA;
        reserveTokenB -= _amountTokenB;
    }
}

// Block 2
// 9.000000000000000000
// 4.444444444444444444
// 0.493827160493827160 TokenB / TokenA

// Block 3
// 8.000000000000000000
// 4.999999999999999999
// 624999999999999999 TokenB / TokenA

// resA * resB = K
// (resA - x) * (resB + y) = resA * resB
//              resA * resB
// x = resA -  -------------
//              (resB + y)
//
//      resA(resB + y) - resA(resB)
// x =  ----------------------------
//             (resB + y)
//
//     resA(resB) + y(resA) - resA(resB)
// x = ----------------------------------
//             y + resB
//.     y * resA
// x = -----------
//.    y + resB
//
// resA * resB = K
// (resA + x) * (resB + y) = resA * resB
//               resA * resB
//  x =          ------------ - resA
//                resB + y

// resA * resB = K
// (resA + y) * (resB - x) = resA * resB
//             resA * resB
// x = resB -  ---------
//.            (resA + y)

//      resB(resA) + y(resB) - resA(resB)
// x = ----------------------------------
//                  y + resA
//
//      y * resB
// x = -----------
//      y + resA
