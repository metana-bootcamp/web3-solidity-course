// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

/// @title ExpoBondingToken - hype/early-adopter weighted bonding curve
/// @dev P = a * e^{k * S}, using 1e18 fixed-point for k. Ether reserve held in contract.
/// Note: costToMint uses a simple discrete sum; for production use an analytic or approximated integral.
contract ExpoBondingToken {
    using PRBMathUD60x18 for uint256;

    uint256 public immutable a; // base (wei), scaled 1e18
    uint256 public immutable k; // growth rate (scaled 1e18)
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Bought(address indexed buyer, uint256 amount, uint256 cost);

    constructor(uint256 _a, uint256 _k) {
        a = _a;
        k = _k; // expect k in 1e18 scale, e.g., 0.08e18
    }

    function price(uint256 s) public view returns (uint256) {
        // a * e^{k * s}
        return a.mul(k.mul(s).exp());
    }

    function costToMint(uint256 amount) public view returns (uint256) {
        // discrete sum approximation; keep amount modest to avoid gas blowup
        uint256 cost;
        uint256 s = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            cost += price(s + i);
        }
        return cost;
    }

    function mint(uint256 amount) external payable {
        require(amount <= 50, "cap per tx");
        uint256 cost = costToMint(amount);
        require(msg.value >= cost, "pay cost");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Bought(msg.sender, amount, cost);
        if (msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
    }
}