// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

library Errors {
    error OutOfBounds();
    error EmptyQueue();
    error InvalidIndexRanges();
    error Unauthorized();
    error NotWithdrawable();
    error InvalidAmount();
    error StatusNotDissolved(bytes pubKey);
}
