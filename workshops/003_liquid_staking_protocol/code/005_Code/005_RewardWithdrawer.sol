// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {PoSDepositPool} from "./PoSDepositPool.sol";
import {Ownable2Step} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable2Step.sol";
import {Ownable} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable.sol";

contract RewardWithdrawer is Ownable2Step {
    receive() external payable {}

    PoSDepositPool public immutable poSDepositPool;

    constructor(address _poSDepositPool) Ownable(msg.sender) {
        poSDepositPool = PoSDepositPool(_poSDepositPool);
    }

    function harvest(uint256 _amount) external onlyOwner {
        poSDepositPool.harvest{value: _amount}();
    }
}
