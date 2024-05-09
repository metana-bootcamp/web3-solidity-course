// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {MetanaEth} from "./MetanaEth.sol";
import {AutoMetanaEth} from "./AutoMetanaEth.sol";
import {ValidatorQueue} from "./ValidatorQueue.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";
import {Ownable2Step} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable2Step.sol";
import {Ownable} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c80b675b8db1d951b8b3734df59530d0d3be064b/contracts/access/Ownable.sol";
import {MetanaSemiFungible} from "./MetanaSemiFungible.sol";

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

    uint256 public pendingWithdrawals;

    MetanaEth public immutable metanaEth;

    AutoMetanaEth public immutable autoMetanaEth;

    address public immutable rewardWithdrawer;

    MetanaSemiFungible public immutable metanaSemiFungible;

    uint256 public batchId;

    event VoluntaryExit(bytes pubKey);

    constructor(
        address _beaconchainDepositContract,
        uint256 _beaconChainDepositAmount,
        address _metanaEth,
        address _autoMetanaEth,
        address _rewardWithdrawer
    ) Ownable(msg.sender) {
        beaconchainDepositContract = IDeposit(_beaconchainDepositContract);
        beaconChainDepositAmount = _beaconChainDepositAmount;
        metanaEth = MetanaEth(_metanaEth);
        autoMetanaEth = AutoMetanaEth(_autoMetanaEth);
        rewardWithdrawer = _rewardWithdrawer;
    }

    function deposit(address _receiver) external payable {
        uint256 _amount = msg.value;
        pendingDeposit += _amount;
        _stake();
        metanaEth.mint(address(this), _amount);
        metanaEth.approve(address(autoMetanaEth), _amount);
        autoMetanaEth.deposit(_amount, _receiver);
    }

    function addAddInitializedValidator(DataTypes.Validator memory _validator)
        external
        onlyOwner
    {
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

    function harvest() external payable {
        if (msg.sender != rewardWithdrawer) revert Errors.Unauthorized();
        uint256 _rewards = msg.value;
        pendingDeposit += _rewards;
        metanaEth.mint(address(autoMetanaEth), _rewards);
        autoMetanaEth.notifyRewardAmount();
        _stake();
    }

    function initiateUnstaking(uint256 _shares, address _receiver) external {
        autoMetanaEth.transferFrom(msg.sender, address(this), _shares);
        uint256 _assets = autoMetanaEth.redeem(
            _shares,
            address(this),
            address(this)
        );
        metanaEth.burn(address(this), _assets);
        _initiateUnstaking(_assets, _receiver);
    }

    function _initiateUnstaking(uint256 _assets, address _receiver) internal {
        pendingWithdrawals += _assets;
        while (pendingWithdrawals % beaconChainDepositAmount >= 1) {
            uint256 _allocationPossible = beaconChainDepositAmount +
                _assets -
                pendingWithdrawals;
            metanaSemiFungible.mint(_receiver, batchId, _allocationPossible);
            DataTypes.Validator memory _validator = stakingValidators.getNext();

            emit VoluntaryExit(_validator.pubKey);

            pendingWithdrawals -= beaconChainDepositAmount;
            _assets -= _allocationPossible;
            batchId++;
        }
        if (_assets > 0) {
            metanaSemiFungible.mint(_receiver, batchId, _assets);
        }
    }
}