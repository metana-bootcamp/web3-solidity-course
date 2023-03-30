// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SimplePaymentChannel {

    address public sender;
    address public recipient;
    uint256 public expiration;

    constructor(address _recipient,uint256 _duration) payable {
        sender = msg.sender;
        recipient = _recipient;
        // solium-disable-next-line security/no-block-members
        expiration = block.timestamp + _duration;
    }

    function isValidSignature(uint256 amount, bytes memory signature) internal view returns(bool) {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this,amount)));
        return recoverSigner(message,signature) == sender;
    }

    function extend(uint256 newExpiration) public {
        require(msg.sender == sender,"SimplePaymentChannel: only sender can extend the expiration");
        require(newExpiration > expiration,"SimplePaymentChannel: newExpiration should be greater than expiration");
        expiration = newExpiration;
    }

    function close(uint256 amount, bytes memory signature) public {
        require(msg.sender == recipient, "SimplePaymentChannel: only recipient can close the channel");
        require(isValidSignature(amount, signature), "SimplePaymentChannel: signature is invalid");

        payable(msg.sender).transfer(amount);
        selfdestruct(payable(sender));
    }

    function claimTimeout() public {
                // solium-disable-next-line security/no-block-members
        require(block.timestamp > expiration,"SimplePaymentChannel: the channel has not expired");
        selfdestruct(payable(sender));
    }

    // Signature methods

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65,"ReceiverPays: signature length mismach");

        bytes32 r;
        bytes32 s;
        uint8 v;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}