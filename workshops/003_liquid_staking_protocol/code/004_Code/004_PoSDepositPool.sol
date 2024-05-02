// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {MetanaEth} from "./MetanaEth.sol";
import {AutoMetanaEth} from "./AutoMetanaEth.sol";
import {ValidatorQueue} from "./ValidatorQueue.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";
import {Ownable2Step} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable2Step.sol";
import {Ownable} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable.sol";

interface IDeposit {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract PoSDepositPool is Ownable2Step {
    using ValidatorQueue for DataTypes.ValidatorDeque;

    DataTypes.ValidatorDeque internal initializedValidators;

    DataTypes.ValidatorDeque internal stakingValidators;

    IDeposit public immutable beaconchainDepositContract;

    uint256 public immutable beaconChainDepositAmount;

    uint256 public pendingDeposit;

    MetanaEth public immutable metanaEth;

    AutoMetanaEth public immutable autoMetanaEth;

    constructor(
        address _beaconchainDepositContract,
        uint256 _beaconChainDepositAmount,
        address _metanaEth,
        address _autoMetanaEth
    ) Ownable(msg.sender) {
        beaconchainDepositContract = IDeposit(_beaconchainDepositContract);
        beaconChainDepositAmount = _beaconChainDepositAmount;
        metanaEth = MetanaEth(_metanaEth);
        autoMetanaEth = AutoMetanaEth(_autoMetanaEth);
    }

    function deposit(address _receiver) external payable {
        uint256 _amount = msg.value;
        pendingDeposit += _amount;
        _stake();
        metanaEth.mint(address(this), _amount);
        metanaEth.approve(address(autoMetanaEth), _amount);
        autoMetanaEth.deposit(_amount, _receiver);
    }

    function addAddInitializedValidator(
        DataTypes.Validator memory _validator
    ) external onlyOwner {
        initializedValidators.add(_validator);
    }

    function _stake() private {
        while (pendingDeposit % beaconChainDepositAmount >= 1) {
            DataTypes.Validator memory _validator = initializedValidators
                .getNext();
            beaconchainDepositContract.deposit{value: beaconChainDepositAmount}(
                _validator.pubKey,
                _validator.withdrawal_credentials,
                _validator.signature,
                _validator.depositDataRoot
            );
            pendingDeposit -= beaconChainDepositAmount;
            stakingValidators.add(_validator);
        }
    }
}
