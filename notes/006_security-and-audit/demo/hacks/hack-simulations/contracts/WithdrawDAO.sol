// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.25;

contract DAO {
    function balanceOf(address addr) returns(uint);
    function transferFrom(address from, address to, uint balance) returns(bool);
    uint256 public totalSupply;
}

contract WithdrawDAO {
    DAO constant public mainDAO = DAO(0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413);
    address public trustee = 0xda4a4626d3e16e094de3225a751aab7128e96526;

    function withdraw() {
        uint balance = mainDAO.balanceOf(msg.sender);

        if(!mainDAO.transferFrom(msg.sender, this, balance) || !msg.sender.send(balance)) {
            throw;
        }
    }

    function trusteeWithdraw() {
        trustee.send((this.balance + mainDAO.balanceOf(this)) - mainDAO.totalSupply());
    }
}