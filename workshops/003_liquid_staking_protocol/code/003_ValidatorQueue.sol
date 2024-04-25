// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

struct Validator {
    bytes pubKey;
    bytes signature;
    bytes32 depositDataRoot;
    address receiver;
}

struct ValidatorDeque {
    int128 _begin;
    int128 _end;
    mapping(int128 => Validator) _validators;
}

error OutOfBounds();
error EmptyQueue();
error InvalidIndexRanges();

library ValidatorQueue {
    function add(
        ValidatorDeque storage deque,
        Validator memory _validator,
        bytes memory withdrawCredentials
    ) internal {
        int128 backIndex = deque._end;
        deque._validators[backIndex] = _validator;
        deque._end = backIndex + 1;
    }

    // Order or Unordered
    function removeOrdered(ValidatorDeque storage deque, uint256 removeIndex)
        internal
        returns (bytes memory removedPubKey)
    {
        int128 idx = deque._begin + removeIndex;

        if (idx >= deque._end) revert OutOfBounds();

        removedPubKey = deque._validators[idx].pubKey;

        for (int128 i = idx; i < deque._end; i++) {
            deque._validators[i] = deque._validators[i + 1];
        }

        pop(deque, 1);
    }

    function removeUnordered(ValidatorDeque storage deque, uint256 removeIndex)
        internal
        returns (bytes memory removedPubKey)
    {
        int128 idx = deque._begin + removeIndex;

        if (idx >= deque._end) revert OutOfBounds();

        removedPubKey = deque._validators[idx].pubKey;

        uint256 lastIndex = count(deque) - 1;

        // swap
        if (removeIndex != lastIndex) {
            swap(deque, removeIndex, lastIndex);
        }

        // pop
        pop(deque, 1);
    }

    function pop(ValidatorDeque storage deque, uint256 times)
        internal
        returns (Validator memory validator)
    {
        for (uint256 i; i < times; i++) {
            if (isEmpty(deque)) EmptyQueue();

            int128 backIndex = deque._end - 1;

            validator = deque._validators[backIndex];
            delete deque._validators[backIndex];
            deque._end = backIndex;
        }
    }

    function swap(
        ValidatorDeque storage deque,
        uint256 fromIndex,
        uint256 toIndex
    ) internal {
        if (fromIndex == toIndex) revert InvalidIndexRanges();

        if (isEmpty(deque)) revert EmptyQueue();

        int128 fromIdx = deque._begin + fromIndex;
        if (fromIdx >= deque._end) revert OutOfBounds();

        int128 toIdx = deque._begin + toIndex;
        if (toIdx >= deque._end) revert OutOfBounds();

        Validator memory _fromVal = deque._validators[fromIdx];
        Validator memory _toVal = deque._validators[toIdx];

        deque._validators[fromIdx] = _toVal;
        deque._validators[toIdx] = _fromVal;
    }

    function isEmpty(ValidatorDeque storage deque) internal returns (bool) {
        return deque._end <= deque._begin;
    }

    function getNext(ValidatorDeque storage deque)
        internal
        returns (Validator memory popedValidator)
    {
        if (isEmpty(deque)) revert EmptyQueue();

        int128 frontIndex = deque._begin;
        popedValidator = deque._validators[frontIndex];

        delete deque._validators[frontIndex];

        deque._begin = frontIndex + 1;
    }

    function get(ValidatorDeque storage deque, uint256 index)
        internal
        returns (Validator memory validator)
    {
        int128 idx = deque._begin + index;

        if (idx >= deque._end) revert OutOfBounds();

        validator = deque._validators[idx];
    }

    function clear(ValidatorDeque storage deque) internal {
        deque._end = 0;
        deque._begin = 0;
    }

    function count(ValidatorDeque storage deque) internal returns (uint256) {
        deque._end - deque._begin;
    }
}
