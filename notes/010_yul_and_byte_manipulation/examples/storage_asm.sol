// SPDX-License-Identified: UNLICENSED

pragma solidity ^0.7.1;

contract StorageDemo {
    
    uint8 data1 = 1;
    uint8 data2 = 2;
    uint8 data3 = 3;
    uint8 data4 = 4;
    
    // get data3 and return it as output
    function getData() public view returns(bytes32) {
        assembly {
            let data := sload(data3.slot)
            let result := and(shr(shl(3,data3.offset), data),0xff)
            mstore(0,result)
            return(0,32)
        }
    }
    
    function getMultipleData() public view returns(bytes32 result3, bytes32 result4) {
        assembly {
            let dataT3 := sload(data3.slot)
            let dataT4 := sload(data4.slot)
            result3 := and(shr(shl(3,data3.offset), dataT3),0xff)
            result4 := and(shr(shl(3,data4.offset), dataT4),0xff)
            mstore(0,dataT3)
            mstore(0x20, result4)
        }
    }
}

// uint8 data3 = 3;
// 3 => 0x03 in 8 bit word size
// 3 => 0x0000000000000000000000000000000000000000000000000000000000000003 in 32 byte word size

// uint8 data4 = 4;
// 4 => 0x04 in 8 bit word size
// 4 => 0x0000000000000000000000000000000000000000000000000000000000000004 in 32 byte word size