// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

// https://holesky.etherscan.io/address/0x48da88102e0a2dc83c4bdaa1a754e80fb481cfab
contract Calculator {
    uint256 public x=10; // slot 0 - 0x0000000000000000000000000000000000000000000000000000000000000000
    uint256 public y=10; // slot 1 - 0x0000000000000000000000000000000000000000000000000000000000000001

    function add() external view returns (uint256) {
        return x + y;
    }
}

// https://holesky.etherscan.io/address/0x1a2ccb65c2d6e582114a0e12f10b267b060c083a
contract Caller {
    Calculator calculator;

    constructor(Calculator _c) {
        calculator = _c;
    }

    function call() external returns(uint256) { // 0x28b5e32b
        return calculator.add(); // 31214
    }
}

