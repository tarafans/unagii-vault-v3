// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'solmate/utils/SafeTransferLib.sol';
import 'src/Treasury.sol';
import 'src/external/curve/ITricryptoPool.sol';
import 'src/external/convex/IBaseRewardPool.sol';
import 'src/external/convex/IBooster.sol';
import 'src/Swap.sol';

contract TreasuryConvexTricrypto is Treasury {
	using SafeTransferLib for ERC20;

	/// @notice contract used to swap CRV/CVX to treasury reward
	Swap public swap;

	/// @notice index of reward in tricrypto pool
	uint8 public immutable index;

	ITricryptoPool internal constant pool = ITricryptoPool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
	/// @dev crvTricrypto LP token
	ERC20 internal constant lpToken = ERC20(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);

	IBaseRewardPool private constant rewardPool = IBaseRewardPool(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03);
	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	ERC20[2] public rewards = [CRV, CVX];
	bool public shouldClaimExtras = true;

	error InvalidIndex();
	error WithdrawAndUnwrapFailed();

	/// @dev pid of tricrypto2 in Convex
	uint8 internal constant pid = 38;

	constructor(
		ERC20 _asset,
		Swap _swap,
		uint8 _index,
		Staking _staking,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized
	) Treasury(_asset, _staking, _nominatedOwner, _admin, _authorized) {
		if (pool.coins(_index) != address(reward)) revert InvalidIndex();

		swap = _swap;
		index = _index;

		_approve();
	}

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	function unstakeAndWithdraw(
		uint256 _lpAmount,
		uint256 _i,
		uint256 _min,
		address _receiver
	) external onlyOwner {
		if (!rewardPool.withdrawAndUnwrap(_lpAmount, true)) revert WithdrawAndUnwrapFailed();

		pool.remove_liquidity_one_coin(_lpAmount, _i, _min);

		ERC20 token = ERC20(pool.coins(_i));
		uint256 balance = token.balanceOf(address(this));
		_withdraw(token, _receiver, balance);
	}

	function changeSwap(Swap _swap) external onlyOwner {
		_unapproveSwap();
		swap = _swap;
		_approveSwap();
	}

	/*////////////////////////////////
	/      Authorized Functions      /
	////////////////////////////////*/

	function reapprove() external onlyAuthorized {
		_unapprove();
		_approve();
	}

	function setShouldClaimExtras(bool _shouldClaimExtras) external onlyAuthorized {
		shouldClaimExtras = _shouldClaimExtras;
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	error ClaimRewardsFailed();

	function _harvest() internal override {
		if (!rewardPool.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		uint256 balance = reward.balanceOf(address(this));

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			swap.swapTokens(address(rewardToken), address(reward), rewardBalance, 1);
		}

		uint256 received = reward.balanceOf(address(this)) - balance;

		reward.safeTransfer(address(staking), received);
	}

	error NothingToInvest();
	error DepositFailed();

	function _invest(uint256 _min) internal override {
		uint256 assetBalance = asset.balanceOf(address(this));

		if (assetBalance == 0) revert NothingToInvest();

		// convert from USDC to USDT
		if (asset != reward) {
			swap.swapTokens(address(asset), address(reward), assetBalance, 1);
			assetBalance = reward.balanceOf(address(this));
		}

		uint256[] memory balances = new uint256[](3);
		balances[index] = assetBalance;

		pool.add_liquidity([balances[0], balances[1], balances[2]], _min);

		uint256 lpBalance = lpToken.balanceOf(address(this));
		if (!booster.deposit(pid, lpBalance, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit USDT/WBTC/WETH in pool
		reward.safeApprove(address(pool), type(uint256).max);
		// approve deposit lpTokens into booster
		lpToken.safeApprove(address(booster), type(uint256).max);
		// approve withdraw lpTokens
		lpToken.safeApprove(address(pool), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		reward.safeApprove(address(pool), 0);
		lpToken.safeApprove(address(booster), 0);
		lpToken.safeApprove(address(pool), 0);

		_unapproveSwap();
	}

	// approve swap rewards to staking reward
	function _approveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}

		if (asset != reward) asset.safeApprove(address(swap), type(uint256).max);
	}

	function _unapproveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}

		if (asset != reward) asset.safeApprove(address(swap), type(uint256).max);
	}
}
