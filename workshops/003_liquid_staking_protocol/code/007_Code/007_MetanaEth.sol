// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c1d6ad5a307945c7825cb3c4c911f2fd017c8725/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c1d6ad5a307945c7825cb3c4c911f2fd017c8725/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract MetanaEth is ERC20, AccessControlDefaultAdminRules {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(uint48 _initialDelay, address _initialDefaultAdmin)
        ERC20("MetanaEth", "METH")
        AccessControlDefaultAdminRules(_initialDelay, _initialDefaultAdmin)
    {}

    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_to, _amount);
    }
}
