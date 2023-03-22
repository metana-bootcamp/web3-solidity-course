// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UltraSoundMoney {
    uint256 public totalSupply;

    function setTotalSupply() public {
        totalSupply = 8;
    }

    function optimizedSetTotalSupply() public {
        assembly {
            sstore(0x00,0x08)
        }
    }
}
