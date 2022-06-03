// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import '../external/convex/IBaseRewardPool.sol';
import '../external/convex/IBooster.sol';
import '../external/curve/IGen2DepositZap.sol';
import '../external/curve/IGen2MetaPool.sol';
import '../Swap.sol';
import '../Strategy.sol';

// strategy for older pre-factory curve metapools
contract WbtcStrategyConvexGen2 is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice contract used to swap CRV/CVX rewards to WBTC
	Swap public swap;

	uint8 immutable pid;
	IGen2MetaPool immutable pool;
	ERC20 immutable poolToken;
	IBaseRewardPool immutable reward;
	IGen2DepositZap immutable zap;

	bool public shouldClaimExtras = true;

	ERC20[2] public rewards = [CRV, CVX];

	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	/// @dev index of WBTC in metapool
	int128 internal constant INDEX_OF_ASSET = 2;
	/// @dev normalize WBTC to 18 decimals + offset pool.get_virtual_price()'s 18 decimals
	uint256 internal constant NORMALIZED_DECIMAL_OFFSET = 1e28;

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
		IGen2DepositZap _zap,
		uint8 _pid,
		Swap _swap
	) Strategy(_vault, _treasury, _authorized) {
		(address lpToken, , , address crvRewards, , ) = booster.poolInfo(_pid);

		poolToken = ERC20(lpToken);
		pool = IGen2MetaPool(_zap.pool());
		reward = IBaseRewardPool(crvRewards);
		zap = _zap;
		pid = _pid;
		swap = _swap;

		_approve();
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		uint256 rewardBalance = reward.balanceOf(address(this));
		if (rewardBalance == 0) return assets;
		assets += rewardBalance.mulDivDown(pool.base_virtual_price(), NORMALIZED_DECIMAL_OFFSET);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function changeSwap(Swap _swap) external onlyOwner {
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

		received = zap.remove_liquidity_one_coin(tokenAmount, INDEX_OF_ASSET, _calculateSlippage(amount));
		asset.safeTransfer(_receiver, received);
	}

	function _harvest() internal override {
		if (!reward.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			// send rewards to treasury
			if (fee > 0) {
				uint256 feeAmount = _calculateFee(rewardBalance);
				rewardToken.safeTransfer(treasury, feeAmount);
				rewardBalance -= feeAmount;
			}

			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}

		asset.safeTransfer(address(vault), asset.balanceOf(address(this)));
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		uint256 min = _calculateSlippage(assetBalance.mulDivDown(NORMALIZED_DECIMAL_OFFSET, pool.base_virtual_price()));

		uint256 received = zap.add_liquidity([0, 0, assetBalance, 0], min);

		if (!booster.deposit(pid, received, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit WBTC into zap
		asset.safeApprove(address(zap), type(uint256).max);
		// approve deposit lpTokens into booster
		poolToken.safeApprove(address(booster), type(uint256).max);
		// approve withdraw lpTokens
		poolToken.safeApprove(address(zap), type(uint256).max);

		// approve swap rewards to WBTC
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}
	}

	function _unapprove() internal {
		asset.safeApprove(address(zap), 0);
		poolToken.safeApprove(address(booster), 0);
		poolToken.safeApprove(address(zap), 0);

		// approve swap rewards to WBTC
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}
	}
}
