// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC1155} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52c36d412e8681053975396223d0ea39687fe33b/contracts/token/ERC1155/ERC1155.sol";

contract MetanaSemiFungible is ERC1155 {
    constructor() ERC1155("") {}

    function mint(
        address _to,
        uint256 _id,
        uint256 _value
    ) external {
        _mint(_to, _id, _value, "");
    }
}
