// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import '../external/convex/IBaseRewardPool.sol';
import '../external/convex/IBooster.sol';
import '../external/curve/IDepositZap.sol';
import '../external/curve/IMetaPool.sol';
import '../interfaces/ISwap.sol';
import '../Strategy.sol';

contract UsdcStrategyConvex is Strategy {
	using SafeTransferLib for ERC20;
	using SafeTransferLib for IMetaPool;

	ISwap public swap;

	IMetaPool immutable pool;
	IBaseRewardPool immutable reward;
	uint8 immutable pid;

	/// @dev child contracts should override this if there are more rewards
	ERC20[2] public rewards = [CRV, CVX];
	bool public shouldClaimExtras = true;

	IDepositZap constant zap = IDepositZap(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
	IBooster constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	uint256 internal constant DECIMAL_OFFSET = 1e12; // to normalize USDC to 18 decimals

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

	constructor(
		Vault _vault,
		address _treasury,
		uint8 _pid
	) Strategy(_vault, _treasury) {
		(address lpToken, , , address crvRewards, , ) = booster.poolInfo(_pid);

		pool = IMetaPool(lpToken);
		reward = IBaseRewardPool(crvRewards);
		pid = _pid;
	}

	/*///////////////////////
	/      Public View      /
  ///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		uint256 rewardBalance = reward.balanceOf(address(this));
		assets = (rewardBalance * pool.get_virtual_price()) / (1e18 * DECIMAL_OFFSET);
		assets += asset.balanceOf(address(this));
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 assets = totalAssets();
		uint256 amount = _assets > assets ? assets : _assets;

		uint256 tokenAmount = (amount * reward.balanceOf(address(this))) / totalAssets();

		uint256 min = _calculateSlippage(amount);

		if (!reward.withdrawAndUnwrap(tokenAmount, true)) revert WithdrawAndUnwrapFailed();
		received = zap.remove_liquidity_one_coin(address(pool), tokenAmount, int128(uint128(2)), min, _receiver);
	}

	function _harvest() internal override {
		if (!reward.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		for (uint8 i = 0; i < rewards.length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));
			if (rewardBalance == 0) continue;

			// send CRV/CVX fee to treasury instead of swapping to USDC
			if (fee > 0) {
				uint256 feeAmount = (rewardBalance * fee) / FEE_BASIS;
				rewardToken.safeTransfer(treasury, feeAmount);
				rewardBalance -= feeAmount;
			}

			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}

		// TODO: figure out whether to transfer to vault, hold for vault or reinvest at this point
		asset.safeTransfer(address(vault), asset.balanceOf(address(this)));
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) return;

		uint256 min = _calculateSlippage((assetBalance * DECIMAL_OFFSET) / pool.get_virtual_price());

		uint256 received = zap.add_liquidity(address(pool), [0, 0, assetBalance, 0], min);
		if (!booster.deposit(pid, received, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/
}
