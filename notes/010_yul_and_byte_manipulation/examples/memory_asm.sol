// SPDX-License-Identified: UNLICENSED

pragma solidity ^0.7.1;

contract Sample {
    
    function getData(uint value) public pure returns(bytes32) {
        assembly {
            function allocate(length) -> pos {
                let freePointer := 0x40 // freePointer starts at 0x40
                pos := mload(freePointer) // memory to stack
                mstore(freePointer, add(pos,length))
            }
            let datasize := 0x20 // 32 bytes
            let offset := allocate(datasize)
            mstore(offset, value)
            return (offset, datasize)
        }
    }
}

// 0x0178fe3f000000000000000000000000000000000000000000000000000000007fffffff

// 2147483647 => 0x000000000000000000000000000000000000000000000000000000007fffffff