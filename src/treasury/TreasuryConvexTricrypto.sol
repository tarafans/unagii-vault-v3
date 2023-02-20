// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'src/Treasury.sol';
import 'src/external/curve/ITricryptoPool.sol';
import 'src/external/convex/IBaseRewardPool.sol';
import 'src/external/convex/IBooster.sol';
import 'src/Swap.sol';

contract TreasuryConvexTricrypto is Treasury {
	/// @notice contract used to swap CRV/CVX rewards to reward
	Swap public swap;

	/// @dev deposit zap
	ITricryptoPool internal constant pool = ITricryptoPool(0x331aF2E331bd619DefAa5DAc6c038f53FCF9F785);
	/// @dev crvTricrypto LP token
	ERC20 internal constant lpToken = ERC20(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);
	IBaseRewardPool private constant rewardPool = IBaseRewardPool(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03);
	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	ERC20[2] public rewards = [CRV, CVX];
	bool public shouldClaimExtras = true;

	/// @dev indices 0: USDT, 1: WBTC, 2: WETH

	constructor(Staking _staking, address[] memory _authorized) Treasury(_staking, _authorized) {}

	error ClaimRewardsFailed();

	function _harvest() internal override {
		if (!rewardPool.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			swap.swapTokens(address(rewardToken), address(reward), rewardBalance, 1);
		}

		received = reward.balanceOf(address(this));
		reward.safeTransfer(address(staking), received);
	}

	function _invest() internal override {
		// if USDC, swap to USDT
		// add_liquidity
		// deposit in booster
	}

	function _withdraw(uint256 _lpAmount) internal override returns (uint256 received) {}
}
