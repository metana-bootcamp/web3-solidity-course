// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Constant Product AMM
contract Uniswapper {
    uint256 public tokenAReserves = 10 * 1e18;
    uint256 public tokenBReserves = 4 * 1e18;

    function getPriceOfA() external view returns (uint256) {
        return (tokenBReserves * 1e18) / tokenAReserves;
    }

    event AmountTokenBRequired(uint256 amount);

    // e.g. buy only 100gm  of chips regardless of price
    function swapTokenBForExactTokenA(uint256 _amountTokenA) external {
        uint256 _tokenBRequired = ((tokenAReserves * tokenBReserves) /
            (tokenAReserves - _amountTokenA)) - tokenBReserves;
        tokenAReserves -= _amountTokenA;
        tokenBReserves += _tokenBRequired;
        emit AmountTokenBRequired(_tokenBRequired);
    }

    // e.g. spend $1 for any amount of chips
    function swapExactTokenBForTokenA(uint256 _amountTokenB) external {
        // code here...
    }

    // e.g. sell as many chips as user spent
    function swapTokenAForExactTokenB(uint256 _amountTokenB) external {
        // code here...
    }

    // e.g. sell chips as per demand regardless of price
    function swapExactTokenAForTokenB(uint256 _amountTokenA) external {
        // code here...
    }
}
