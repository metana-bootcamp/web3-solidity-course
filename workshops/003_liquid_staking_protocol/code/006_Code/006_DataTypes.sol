// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

library DataTypes {
    struct Validator {
        bytes pubKey;
        bytes withdrawal_credentials;
        bytes signature;
        bytes32 depositDataRoot;
    }

    struct ValidatorDeque {
        int128 _begin;
        int128 _end;
        mapping(int128 => Validator) _validators;
    }

    enum ValidatorStatus {
        None,
        Staking,
        Withdrawable,
        Dissolved
    }
}
