// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC4626.sol";

contract AutoCompoundingVault is ERC4626 {
    uint256 public totalStaked;

    uint256 public rewardPerTokenStored;

    uint256 public periodFinish;

    uint256 public lastUpdateTime;

    uint256 public rewardRate;

    uint256 public rewards;

    uint256 public rewardPerTokenPaid;

    uint256 public constant FEE_DENOMINATOR = 1_000_000;

    uint256 public platformFee;

    address public platform;

    uint256 public constant REWARDS_DURATION = 7 days;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {}

    modifier updateReward(bool updateEarned) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (updateEarned) {
            rewards = earned();
            rewardPerTokenPaid = rewardPerTokenStored;
        }

        _;
    }

    function notifyRewardAmount() external updateReward(false) {
        uint256 rewardBalance = asset.balanceOf(address(this)) -
            totalStaked -
            earned();
        rewardRate = rewardBalance / REWARDS_DURATION;

        if (rewardRate == 0) revert();

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARDS_DURATION;
    }

    function earned() public view returns (uint256) {
        return
            (totalStaked * ((rewardPerToken()) - rewardPerTokenPaid)) /
            1e18 +
            rewards;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) *
                1e18) / totalStaked);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        _stake(assets);
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        _withdraw(assets);
    }

    function harvest() public updateReward(true) {
        uint256 _rewards = rewards;
        if (rewards != 0) {
            rewards = 0;

            // calculate fees
            uint256 _feeAmount = (_rewards * platformFee) / FEE_DENOMINATOR;

            _rewards -= _feeAmount;

            // transfer fees to contract developer
            asset.transfer(platform, _rewards);

            // restake the remaining rewards. <= auto compounding
            _stake(_rewards);
        }
    }

    function _stake(uint256 amount) internal updateReward(true) {
        totalStaked += amount;
    }

    function _withdraw(uint256 assets) internal updateReward(true) {
        if (assets > totalStaked) harvest();
        totalStaked -= assets;
    }

    function totalAssets() public view override returns (uint256) {}
}

