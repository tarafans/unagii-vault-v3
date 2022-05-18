// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import 'forge-std/console.sol'; // TODO: remove when done

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import '../external/convex/IBaseRewardPool.sol';
import '../external/convex/IBooster.sol';
import '../external/curve/IDepositZap.sol';
import '../external/curve/IMetaPool.sol';
import '../interfaces/ISwap.sol';
import '../libraries/Ownership.sol';
import '../Strategy.sol';

contract UsdcStrategyConvex is Strategy {
	using SafeTransferLib for ERC20;
	using SafeTransferLib for IMetaPool;

	/// @notice contract used to swap CRV/CVX rewards to USDC
	ISwap public swap;

	uint8 immutable pid;
	IMetaPool immutable pool;
	IBaseRewardPool immutable reward;

	/// @dev child contracts should override this if there are more rewards
	ERC20[2] public rewards = [CRV, CVX];
	bool public shouldClaimExtras = true;

	IDepositZap constant zap = IDepositZap(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
	IBooster constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	int128 internal constant INDEX_OF_ASSET = 2; // index of USDC in metapool
	uint256 internal constant DECIMAL_OFFSET = 1e12; // normalize USDC to 18 decimals

	/*///////////////
	/     Events    /
	///////////////*/

	/*///////////////
	/     Errors    /
	///////////////*/

	error InvalidPool();

	error ClaimRewardsFailed();
	error WithdrawAndUnwrapFailed();
	error DepositFailed();

	error NothingToInvest();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		uint8 _pid,
		ISwap _swap
	) Strategy(_vault, _treasury, _authorized) {
		(address lpToken, , , address crvRewards, , ) = booster.poolInfo(_pid);

		pool = IMetaPool(lpToken);
		reward = IBaseRewardPool(crvRewards);
		pid = _pid;
		swap = _swap;

		_approve();
	}

	/*///////////////////////
	/      Public View      /
  ///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		assets += asset.balanceOf(address(this));
		uint256 rewardBalance = reward.balanceOf(address(this));
		if (rewardBalance == 0) return assets;
		assets += (rewardBalance * pool.get_virtual_price()) / (1e18 * DECIMAL_OFFSET);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function changeSwap(ISwap _swap) external onlyOwner {
		_unapprove();
		swap = _swap;
		_approve();
	}

	/*////////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized      /
	////////////////////////////////////////////////*/

	function reapprove() external onlyAuthorized {
		_unapprove();
		_approve();
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 assets = totalAssets();
		if (assets == 0) return 0; // nothing to withdraw

		uint256 amount = _assets > assets ? assets : _assets;

		uint256 tokenAmount = (amount * reward.balanceOf(address(this))) / totalAssets();

		if (!reward.withdrawAndUnwrap(tokenAmount, true)) revert WithdrawAndUnwrapFailed();
		received = zap.remove_liquidity_one_coin(address(pool), tokenAmount, INDEX_OF_ASSET, 0, _receiver);
	}

	function _harvest() internal override {
		if (!reward.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		for (uint8 i = 0; i < rewards.length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			// send rewards to treasury
			if (fee > 0) {
				uint256 feeAmount = (rewardBalance * fee) / FEE_BASIS;
				rewardToken.safeTransfer(treasury, feeAmount);
				rewardBalance -= feeAmount;
			}

			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}

		// TODO: check if _investing costs less gas here
		asset.safeTransfer(address(vault), asset.balanceOf(address(this)));
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		uint256 received = zap.add_liquidity(address(pool), [0, 0, assetBalance, 0], 0);

		if (!booster.deposit(pid, received, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit USDC into zap
		asset.safeApprove(address(zap), type(uint256).max);
		// approve deposit lpTokens into booster
		pool.safeApprove(address(booster), type(uint256).max);
		// approve withdraw lpTokens
		pool.safeApprove(address(zap), type(uint256).max);

		// approve swap rewards to USDC
		for (uint8 i = 0; i < rewards.length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}
	}

	function _unapprove() internal {
		asset.safeApprove(address(zap), 0);
		pool.safeApprove(address(booster), 0);
		pool.safeApprove(address(zap), 0);

		// approve swap rewards to USDC
		for (uint8 i = 0; i < rewards.length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}
	}
}
