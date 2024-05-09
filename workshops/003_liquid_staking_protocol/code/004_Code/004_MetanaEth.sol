// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

// Constant Product AMM
contract MetanaEth is ERC20 {
    constructor() ERC20("MetanaEth","METH") {

    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}