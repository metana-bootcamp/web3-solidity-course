// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

// Liquidity Pool Contract
contract Uniswapper {
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(IERC20 $tokenA, IERC20 $tokenB) {
        tokenA = $tokenA;
        tokenB = $tokenB;
    }

    function getTokenAReserves() public view returns (uint256) {
        return tokenA.balanceOf(address(this));
    }

    function getTokenBReserves() public view returns (uint256) {
        return tokenB.balanceOf(address(this));
    }

    function getPriceOfA() external view returns (uint256) {
        return (getTokenBReserves() * 1e18) / getTokenAReserves();
    }

    function getPriceOfB() external view returns (uint256) {
        return (getTokenAReserves() * 1e18) / getTokenBReserves();
    }

    // e.g. buy only 100gm  of chips regardless of price
    function swapTokenBForExactTokenA(uint256 $amountTokenA) external {
        uint256 _tokenAReserves = getTokenAReserves();
        uint256 _tokenBReserves = getTokenBReserves();
        uint256 _tokenBRequired = ((_tokenAReserves * _tokenBReserves) /
            (_tokenAReserves - $amountTokenA)) - _tokenBReserves;
        tokenB.transferFrom(msg.sender, address(this), _tokenBRequired);
        tokenA.transfer(msg.sender, $amountTokenA);
    }

    // e.g. spend $1 for any amount of chips
    function swapExactTokenBForTokenA(uint256 _amountTokenB) external {
        uint256 _tokenAReserves = getTokenAReserves();
        uint256 _tokenBReserves = getTokenBReserves();
        // calculate tokenA amount to be transferred
        uint256 _amountTokenA = _tokenAReserves -
            ((_tokenAReserves * _tokenBReserves) /
                (_tokenBReserves + _amountTokenB));
        tokenB.transferFrom(msg.sender, address(this), _amountTokenB);
        // transfer tokenA to the user
        tokenA.transfer(msg.sender, _amountTokenA);
    }

    // e.g. sell as many chips as user spent
    function swapTokenAForExactTokenB(uint256 $amountTokenB) external {
        uint256 _tokenAReserves = getTokenAReserves();
        uint256 _tokenBReserves = getTokenBReserves();
        // calculate amount of tokenA required against _amountTokenB
        uint256 _amountTokenARequired = ((_tokenAReserves * _tokenBReserves) /
            (_tokenBReserves + $amountTokenB)) - _tokenAReserves;
        // tokenA is transferred from user to this contract
        tokenA.transferFrom(msg.sender, address(this), _amountTokenARequired);
        // transfer _amountTokenB tokenB to user
        tokenB.transfer(msg.sender, $amountTokenB);
    }

    // e.g. sell chips as per demand regardless of price
    function swapExactTokenAForTokenB(uint256 $amountTokenA) external {
        uint256 _tokenAReserves = getTokenAReserves();
        uint256 _tokenBReserves = getTokenBReserves();
        // calculate tokenB amount to be transferred
        uint256 _amountTokenB = _tokenBReserves -
            ((_tokenAReserves * _tokenBReserves) /
                (_tokenAReserves + $amountTokenA));
        // _amountTokenA is transfered from user to this contract
        tokenA.transferFrom(msg.sender, address(this), $amountTokenA);
        // transfer tokenB to the user
        tokenB.transfer(msg.sender, _amountTokenB);
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
