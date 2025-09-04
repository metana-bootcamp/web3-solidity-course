// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract SmartWallet {
    // Assets
    // 1. 1 ETH
    // 2. 100 USDC
    // 3. 50 USDT

    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    function execute(Call[] memory calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].to.call{value: calls[i].value}(
                calls[i].data
            );
            require(success);
        }
    }
}
