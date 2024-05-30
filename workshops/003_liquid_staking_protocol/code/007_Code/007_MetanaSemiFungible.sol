// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c1d6ad5a307945c7825cb3c4c911f2fd017c8725/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c1d6ad5a307945c7825cb3c4c911f2fd017c8725/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract MetanaSemiFungible is ERC1155, AccessControlDefaultAdminRules {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(uint48 _initialDelay, address _initialDefaultAdmin)
        ERC1155("")
        AccessControlDefaultAdminRules(_initialDelay, _initialDefaultAdmin)
    {}

    function mint(
        address _to,
        uint256 _id,
        uint256 _value
    ) external onlyRole(MINTER_ROLE) {
        _mint(_to, _id, _value, "");
    }

    function burn(
        address _to,
        uint256 _id,
        uint256 _value
    ) external onlyRole(BURNER_ROLE) {
        _burn(_to, _id, _value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlDefaultAdminRules, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
