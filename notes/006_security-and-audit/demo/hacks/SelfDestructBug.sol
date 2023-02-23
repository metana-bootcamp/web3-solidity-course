// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Master {
   
    function doStuff() public pure returns (uint) {
        return 6;
    }
    
    function destroy(address payable recipient) public {
        selfdestruct(recipient);
    }
    
    receive() external payable {}
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}

contract Child {
    address public master;
    address payable public owner;
    
    constructor(address masterAddress) public {
        master = masterAddress; 
        owner = msg.sender;
    }
    
    function doStuff() public view returns(uint){
        (bool success, bytes memory ret) = 
        master.staticcall(abi.encodeWithSignature("doStuff()"));
        
        require(success, "doStuff failed");
        return( abi.decode(ret, (uint)));
    }
    
    function commitSuicide() public {
        (bool success, ) = 
        master.delegatecall(abi.encodeWithSignature("destroy(address)", owner));
        require(success, "failed to suicide");
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    receive() external payable {}
}

contract KillMaster {
    address public master;
    address payable public owner;
    
    constructor(address masterAddress) public {
        master = masterAddress; 
        owner = msg.sender;
    }
    
    
    function commitSuicide() public {
        (bool success, ) = 
        master.call(abi.encodeWithSignature("destroy(address)", owner));
        require(success, "failed to suicide");
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    receive() external payable {}
}
