// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LinearBondingToken - predictable community token bonding curve
/// @dev Simple linear price: P = m * S + b. Ether reserve held in contract.
contract LinearBondingToken {
    uint256 public immutable m; // slope (wei per token)
    uint256 public immutable b; // base price (wei)
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Bought(address indexed buyer, uint256 amount, uint256 cost);
    event Sold(address indexed seller, uint256 amount, uint256 refund);

    constructor(uint256 _m, uint256 _b) {
        m = _m;
        b = _b;
    }

    function price(uint256 s) public view returns (uint256) {
        return m * s + b;
    }

    /// @notice integral of P from S -> S+amount
    function costToMint(uint256 amount) public view returns (uint256) {
        uint256 s1 = totalSupply;
        uint256 s2 = totalSupply + amount;
        return m * (s1 + s2 + 1) * amount / 2 + b * amount;
    }

    function mint(uint256 amount) external payable {
        uint256 cost = costToMint(amount);
        require(msg.value >= cost, "pay cost");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Bought(msg.sender, amount, cost);
        if (msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
    }

    function refund(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "bal");
        uint256 s1 = totalSupply;
        uint256 s2 = totalSupply - amount;
        uint256 refundAmt = m * (s1 + s2 + 1) * amount / 2 + b * amount;
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Sold(msg.sender, amount, refundAmt);
        payable(msg.sender).transfer(refundAmt);
    }
}