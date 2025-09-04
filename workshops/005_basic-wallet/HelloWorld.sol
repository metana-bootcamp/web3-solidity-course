// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract HelloWorld {
    event GreetHelloWorld();

    /**
     * @dev Prints Hello World string
     */
    function print() public pure returns (string memory) {
        return "Hello World!";
    }

    function greet() external {
        emit GreetHelloWorld();
    }
}