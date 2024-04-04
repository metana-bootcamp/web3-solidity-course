// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC4626.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable2Step.sol";

error ZeroAddress();
error ExceedsMax();

contract AutoCompoundingVault is ERC4626, Ownable2Step {
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

    uint256 public constant MAX_PLATFORM_FEE = 200_000;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address owner
    ) ERC4626(_asset, _name, _symbol) Ownable(owner) {}

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        if (_platformFee > MAX_PLATFORM_FEE) revert ExceedsMax();
        platformFee = _platformFee;
    }

    function setPlatform(address _platform) external onlyOwner {
        if (_platform == address(0)) revert ZeroAddress();
        platform = _platform;
    }

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

    function assetsPerShare() external view returns (uint256) {
        return previewRedeem(1e18);
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

    function afterDeposit(uint256 assets, uint256) internal override {
        _stake(assets);
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
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

    function totalAssets() public view override returns (uint256) {
        uint256 _totalStaked = totalStaked;
        uint256 _rewards = ((_totalStaked *
            (rewardPerToken() - rewardPerTokenPaid)) / 1e18) + rewards;
        return
            _totalStaked +
            (
                (
                    _rewards == 0
                        ? 0
                        : _rewards -
                            ((_rewards * platformFee) / FEE_DENOMINATOR)
                )
            );
    }
}
