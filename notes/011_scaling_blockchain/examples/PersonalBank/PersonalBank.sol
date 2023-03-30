// SPDX-License-Identified: UNLICENSED

pragma solidity ^0.8.0;

contract PersonalBank {
    address owner;
    
    constructor() payable {
        owner = msg.sender;
    }
    
    receive() external payable {
    }
    
    function cashCheque(address payable to, uint256 amount,
                        bytes32 r, bytes32 s, uint8 v)
                public {
        bytes32 messageHash = keccak256(abi.encodePacked(to, amount));
        
        bytes32 messageHash2 = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", messageHash
        ));
        
        require(ecrecover(messageHash2, v, r, s) == owner, "bad signature");
        
        to.transfer(amount);
    }
}