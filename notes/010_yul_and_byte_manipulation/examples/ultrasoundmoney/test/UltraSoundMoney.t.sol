// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import 'src/UltraSoundMoney.sol';

contract UltraSoundMoneyTest is Test {
    UltraSoundMoney u;
    function setUp() public {
      u = new UltraSoundMoney();
    }

    function testSetTotalSupply() public {
        u.setTotalSupply();
        // assertEq(
        //     u.totalSupply(),
        //     8
        // );
    }

    function testOptimizedSetTotalSupply() public {
        u.optimizedSetTotalSupply();
        // assertEq(
        //     u.totalSupply(),
        //     8
        // );
    }
}