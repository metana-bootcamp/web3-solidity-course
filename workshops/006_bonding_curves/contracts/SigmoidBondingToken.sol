// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

/// @title SigmoidBondingToken - S-curve with soft ceiling
/// @dev P = L / (1 + e^{-k(S - S0)}); parameters use 1e18 fixed-point. Ether reserve held in contract.
/// costToMint uses discrete sum; for production use an analytic approximation and guard gas.
contract SigmoidBondingToken {
    using PRBMathUD60x18 for uint256;

    uint256 public immutable L;   // ceiling price (1e18)
    uint256 public immutable k;   // steepness (1e18)
    uint256 public immutable S0;  // inflection point (tokens)
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Bought(address indexed buyer, uint256 amount, uint256 cost);

    constructor(uint256 _L, uint256 _k, uint256 _S0) {
        L = _L;
        k = _k;
        S0 = _S0;
    }

    function price(uint256 s) public view returns (uint256) {
        // P = L / (1 + exp(-k*(s-S0)))
        if (s >= S0) {
            uint256 expPos = k.mul(s - S0).exp();
            return L.mul(expPos).div(1e18 + expPos); // L * expPos / (1 + expPos)
        } else {
            uint256 expPos = k.mul(S0 - s).exp(); // exp(k*(S0 - s)) > 1
            return L.div(1e18 + expPos);           // L / (1 + expPos)
        }
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