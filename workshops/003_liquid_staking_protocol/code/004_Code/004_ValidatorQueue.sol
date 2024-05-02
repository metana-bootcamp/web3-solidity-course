// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/utils/math/SafeCast.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";

library ValidatorQueue {
    function add(DataTypes.ValidatorDeque storage deque, DataTypes.Validator memory _validator)
        internal
    {
        int128 backIndex = deque._end;
        deque._validators[backIndex] = _validator;
        deque._end = backIndex + 1;
    }

    // Order or Unordered
    function removeOrdered(DataTypes.ValidatorDeque storage deque, uint256 removeIndex)
        internal
        returns (bytes memory removedPubKey)
    {
        int128 idx = SafeCast.toInt128(
            int256(deque._begin) + SafeCast.toInt256(removeIndex)
        );

        if (idx >= deque._end) revert Errors.OutOfBounds();

        removedPubKey = deque._validators[idx].pubKey;

        for (int128 i = idx; i < deque._end; i++) {
            deque._validators[i] = deque._validators[i + 1];
        }

        pop(deque, 1);
    }

    function removeUnordered(DataTypes.ValidatorDeque storage deque, uint256 removeIndex)
        internal
        returns (bytes memory removedPubKey)
    {
        int128 idx = SafeCast.toInt128(
            int256(deque._begin) + SafeCast.toInt256(removeIndex)
        );

        if (idx >= deque._end) revert Errors.OutOfBounds();

        removedPubKey = deque._validators[idx].pubKey;

        uint256 lastIndex = count(deque) - 1;

        // swap
        if (removeIndex != lastIndex) {
            swap(deque, removeIndex, lastIndex);
        }

        // pop
        pop(deque, 1);
    }

    function pop(DataTypes.ValidatorDeque storage deque, uint256 times)
        internal
        returns (DataTypes.Validator memory validator)
    {
        for (uint256 i; i < times; i++) {
            if (isEmpty(deque)) revert Errors.EmptyQueue();

            int128 backIndex = deque._end - 1;

            validator = deque._validators[backIndex];
            delete deque._validators[backIndex];
            deque._end = backIndex;
        }
    }

    function swap(
        DataTypes.ValidatorDeque storage deque,
        uint256 fromIndex,
        uint256 toIndex
    ) internal {
        if (fromIndex == toIndex) revert Errors.InvalidIndexRanges();

        if (isEmpty(deque)) revert Errors.EmptyQueue();

        int128 fromIdx = SafeCast.toInt128(
            int256(deque._begin) + SafeCast.toInt256(fromIndex)
        );
        if (fromIdx >= deque._end) revert Errors.OutOfBounds();

        int128 toIdx = SafeCast.toInt128(
            int256(deque._begin) + SafeCast.toInt256(toIndex)
        );

        if (toIdx >= deque._end) revert Errors.OutOfBounds();

        DataTypes.Validator memory _fromVal = deque._validators[fromIdx];
        DataTypes.Validator memory _toVal = deque._validators[toIdx];

        deque._validators[fromIdx] = _toVal;
        deque._validators[toIdx] = _fromVal;
    }

    function isEmpty(DataTypes.ValidatorDeque storage deque)
        internal
        view
        returns (bool)
    {
        return deque._end <= deque._begin;
    }

    function getNext(DataTypes.ValidatorDeque storage deque)
        internal
        returns (DataTypes.Validator memory popedValidator)
    {
        if (isEmpty(deque)) revert Errors.EmptyQueue();

        int128 frontIndex = deque._begin;
        popedValidator = deque._validators[frontIndex];

        delete deque._validators[frontIndex];

        deque._begin = frontIndex + 1;
    }

    function get(DataTypes.ValidatorDeque storage deque, uint256 index)
        internal
        view
        returns (DataTypes.Validator memory validator)
    {
        int128 idx = SafeCast.toInt128(
            int256(deque._begin) + SafeCast.toInt256(index)
        );

        if (idx >= deque._end) revert Errors.OutOfBounds();

        validator = deque._validators[idx];
    }

    function clear(DataTypes.ValidatorDeque storage deque) internal {
        deque._end = 0;
        deque._begin = 0;
    }

    function count(DataTypes.ValidatorDeque storage deque)
        internal
        view
        returns (uint256)
    {
        return uint256(int256(deque._end - deque._begin));
    }
}
