// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract LongLivedPaymentChannel {
    address public sender;      // The account sending payments.
    address public recipient;   // The account receiving the payments.
    uint256 public withdrawn;   // How much the recipient has already withdrawn.

    // How much time the recipient has to respond when the sender initiates
    // channel closure.
    uint256 public closeDuration;
    // When the payment channel closes. Initially effectively infinite.
    uint256 public expiration = 2**256-1;

    constructor (address _recipient, uint256 _closeDuration)
        payable
    {
        sender = msg.sender;
        recipient = _recipient;
        closeDuration = _closeDuration;
    }

    function isValidSignature(uint256 amount, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));

        // Check that the signature is from the payment sender.
        return recoverSigner(message, signature) == sender;
    }

    // The recipient can close the channel at any time by presenting a signed
    // amount from the sender. The recipient will be sent that amount, and the
    // remainder will go back to the sender.
    function close(uint256 amount, bytes memory signature) public {
        require(msg.sender == recipient, "LongLivedPaymentChannel: only recipient allowed to close channel");
        require(isValidSignature(amount, signature),"LongLivedPaymentChannel: signature invalid");

        require(amount >= withdrawn, "LongLivedPaymentChannel: amount should be greater than equal to withdrawn");
        payable(msg.sender).transfer(amount - withdrawn);

        selfdestruct(payable(sender));
    }

    event StartSenderClose();

    function startSenderClose() public {
        require(msg.sender == sender,"LongLivedPaymentChannel: only sender can close the channel");
        emit StartSenderClose();
        // solium-disable-next-line security/no-block-members
        expiration = block.timestamp + closeDuration;
    }

    // If the timeout is reached without the recipient closing the channel, then
    // the ether is released back to the sender.
    function claimTimeout() public {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= expiration, "LongLivedPaymentChannel: time is not yet expired");
        address payable pSender = payable(sender);
        selfdestruct(pSender);
    }

    function deposit() public payable {
        require(msg.sender == sender,"LongLivedPaymentChannel: only sender can deposit");
    }

    function withdraw(uint256 amountAuthorized, bytes memory signature) public {
        require(msg.sender == recipient, "LongLivedPaymentChannel: only recipient can withdraw");

        require(isValidSignature(amountAuthorized, signature),"LongLivedPaymentChannel: signature is not valid");

        // Make sure there's something to withdraw (guards against underflow)
        require(amountAuthorized > withdrawn,"LongLivedPaymentChannel: not authorized to withdraw this amount");
        uint256 amountToWithdraw = amountAuthorized - withdrawn;

        withdrawn += amountToWithdraw;
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65,"LongLivedPaymentChannel: wrong signature");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // solium-disable-next-line security/no-inline-assembly
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