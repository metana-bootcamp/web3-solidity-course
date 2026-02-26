// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

/// @title LogBondingToken - stabilizing bonding curve
/// @dev P = k * ln(S + c), 1e18 fixed-point. Ether reserve held in contract.
/// Note: costToMint uses discrete sum for clarity; optimize with approximations for production.
contract LogBondingToken {
    using PRBMathUD60x18 for uint256;

    uint256 public immutable k; // slope multiplier (1e18)
    uint256 public immutable c; // offset to avoid ln(0) (1e18)
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Bought(address indexed buyer, uint256 amount, uint256 cost);

    constructor(uint256 _k, uint256 _c) {
        k = _k;
        c = _c;
    }

    function price(uint256 s) public view returns (uint256) {
        return k.mul((s + c).ln());
    }

    function costToMint(uint256 amount) public view returns (uint256) {
        uint256 cost;
        uint256 s = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            cost += price(s + i);
        }
        return cost;
    }

    function mint(uint256 amount) external payable {
        uint256 cost = costToMint(amount);
        require(msg.value >= cost, "pay cost");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Bought(msg.sender, amount, cost);
        if (msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
    }
}