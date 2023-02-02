// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.1;

contract Sample {
    function helloFn() public pure returns(string memory name) {
        assembly {
            let x:= 1
            let y := "Hello World"
            name := y
        }
    }
    
    function fnAdd(uint input) public pure returns(uint x, uint y) {
        assembly {
            function f(val) -> a,b {
                a := add(val,1)
                b := val
            }
            x, y := f(input)
        }
    }
    
    function fnSwitch(uint input) public pure returns(uint b) {
        assembly {
            switch input
                case 0 {
                    b := 12
                }
                case 1 {
                    b := 13
                }
                default {
                    b := add(input,1) // mul, div, sub
                }
        }
    }
    
    function fnLoop(uint max) public pure returns(uint result) {
        assembly {
            for {let i := 0 }
            lt(i, 20)
            { i := add(i,1)} // add(a,b)
            {
                if lt(i,3) { continue }
                if gt(i, max) {break}
                result := add(result,1)
            }
        }
    }
    
    function getCode(address contractAddress) public view returns(bytes memory codehash) {
        assembly {
            codehash := extcodehash(contractAddress)
        }
    }
    
    function srTest(uint8 x) public pure returns(uint8 result) {
        assembly {
            result := shr(1,x)
        }
        /**
         * Explanation: shift right
         * 00001111 => 15
         * \\\\\\\\\
         *  00000111- => 7
         */ 
    }
    
    function countUnsetBit(uint8 data) public pure returns(uint8 result) {
        for(uint i = 0; i < 8 ; i++) {
            if(((data >> i) & 1) == 0) {
                result++;
            }
        }
        /**
         * Explanation and operation
         * num1 = 00001111
         * operation = and
         * num2 = 10101010
         * result = 0000010
         */
    }
    
    function countUnsetBitInAsm(uint8 data) public pure returns(uint8 result) {
        assembly {
            for {let i := 0 }
            lt(i,8)
            {i := add(i,1)} 
            {
                let bytesShifted := shr(i,data)
                let andResult := and(bytesShifted,1)
                if eq(andResult,0) {
                    result := add(result,1)
                }
            }
        }
    }
}