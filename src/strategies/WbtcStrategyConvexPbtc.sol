// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'forge-std/console.sol';

import '../external/convex/IBaseRewardPool.sol';
import '../external/convex/IBooster.sol';
import '../external/curve/IGen2DepositZap.sol';
import '../external/curve/IGen2MetaPool.sol';
import '../interfaces/ISwap.sol';
import '../Strategy.sol';

contract WbtcStrategyConvexPbtc is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice contract used to swap CRV/CVX rewards to WBTC
	ISwap public swap;

	uint8 internal constant pid = 18;
	IGen2MetaPool constant pool = IGen2MetaPool(0x7F55DDe206dbAD629C080068923b36fe9D6bDBeF);
	ERC20 constant poolToken = ERC20(0xDE5331AC4B3630f94853Ff322B66407e0D6331E8);
	IBaseRewardPool constant reward = IBaseRewardPool(0x2d3C90AEB11D1393CA839Afc9587515B1325D77A);
	IGen2DepositZap constant zap = IGen2DepositZap(0x11F419AdAbbFF8d595E7d5b223eee3863Bb3902C);

	bool public shouldClaimExtras = true;

	ERC20[3] public rewards = [CRV, CVX, PNT];

	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
	ERC20 internal constant PNT = ERC20(0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD);

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
		ISwap _swap
	) Strategy(_vault, _treasury, _authorized) {
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
