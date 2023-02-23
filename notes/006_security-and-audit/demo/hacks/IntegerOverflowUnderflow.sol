// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeMath{
    function add(uint8 a, uint8 b) internal pure returns(uint8){
        require(a + b > a, "SafeMath: Integer Overflowed");
        return a+b;
    }
    
    function sub(uint8 a, uint8 b) internal pure returns(uint8){
        require(a - b < a, "SafeMath: Integer Underflowed" );
        return a - b;
    }
}

contract Math {

using SafeMath for uint8;

// Integer Overflow
function add (uint8 a , uint8 b) public pure returns(uint8){
    return a.add(b);
}

// Integer Underflow 
function sub (uint8 a, uint8 b) public pure returns(uint8){
    return a.sub(b);
}
   
}