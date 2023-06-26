// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'forge-std/console2.sol';

import '../Swap.sol';
import '../Strategy.sol';
import {IRewardPoolDepositWrapper} from '../external/aura/IRewardPoolDepositWrapper.sol';
import {IBaseRewardPool4626} from '../external/aura/IBaseRewardPool4626.sol';
import {IAsset, IVault} from '../external/balancer/IVault.sol';
import {IPool} from '../external/balancer/IPool.sol';

abstract contract StrategyAura is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice contract used to swap BAL & AURA rewards to asset
	Swap public swap;

	// aura addresses
	IBaseRewardPool4626 public immutable reward;
	IRewardPoolDepositWrapper public constant depositWrapper =
		IRewardPoolDepositWrapper(0xB188b1CB84Fb0bA13cb9ee1292769F903A9feC59);

	/// balancer vault contract
	IVault public constant balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

	// balancer pool info
	bytes32 public immutable balancerPoolId;
	IPool public immutable balancerPool;
	IAsset[] public balancerPoolAssets;
	uint256 public immutable balancerPoolAssetIndex;
	uint256 public immutable balancerPoolLength;

	// rewards
	ERC20 public constant BAL = ERC20(0xba100000625a3754423978a60c9317c58a424e3D);
	ERC20 public constant AURA = ERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
	ERC20[2] public rewards = [BAL, AURA];

	constructor(
		Vault _vault,
		address _treasury,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap,
		address _reward,
		bytes32 _balancerPoolId,
		uint256 _balancerPoolAssetIndex
	) Strategy(_vault, _treasury, _nominatedOwner, _admin, _authorized) {
		swap = _swap;
		reward = IBaseRewardPool4626(_reward);

		balancerPoolId = _balancerPoolId;
		balancerPoolAssetIndex = _balancerPoolAssetIndex;

		(address balancerPoolAddress, ) = balancer.getPool(balancerPoolId);
		balancerPool = IPool(balancerPoolAddress);
		(address[] memory balancerPoolAssetAddresses, , ) = balancer.getPoolTokens(balancerPoolId);

		if (balancerPoolAssetAddresses[balancerPoolAssetIndex] != address(asset)) {
			revert InvalidBalancerPoolAssetIndex();
		}

		balancerPoolLength = balancerPoolAssetAddresses.length;
		balancerPoolAssets = new IAsset[](balancerPoolLength);

		for (uint8 i = 0; i < balancerPoolLength; ++i) {
			balancerPoolAssets[i] = IAsset(balancerPoolAssetAddresses[i]);
		}

		_approve();
	}

	function totalAssets() public view override returns (uint256) {
		uint256 rewardBalance = reward.balanceOf(address(this));
		if (rewardBalance == 0) return 0;
		return rewardBalance.mulDivDown(balancerPool.getRate(), 1e18);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function changeSwap(Swap _swap) external onlyOwner {
		_unapproveSwap();
		swap = _swap;
		_approveSwap();
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

	enum ExitKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT,
		EXACT_BPT_IN_FOR_ALL_TOKENS_OUT
	}

	function _withdraw(uint256 _assets) internal override returns (uint256 received) {
		uint256 bpAmount = _assets.mulDivDown(1e18, balancerPool.getRate());

		if (!reward.withdrawAndUnwrap(bpAmount, true)) revert WithdrawAndUnwrapFailed();

		uint256[] memory minAmountsOut = new uint256[](balancerPoolAssets.length);
		minAmountsOut[balancerPoolAssetIndex] = _calculateSlippage(bpAmount);

		uint256 balanceBefore = asset.balanceOf(address(this));

		IVault.ExitPoolRequest memory exitPoolRequest = IVault.ExitPoolRequest({
			assets: balancerPoolAssets,
			minAmountsOut: minAmountsOut,
			userData: abi.encode(0, bpAmount, balancerPoolAssetIndex), // 0 is enum for EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
			toInternalBalance: false
		});
		balancer.exitPool(balancerPoolId, address(this), payable(address(this)), exitPoolRequest);

		unchecked {
			received = asset.balanceOf(address(this)) - balanceBefore;
		}

		asset.safeTransfer(address(vault), received);
	}

	function _harvest() internal override {
		reward.getReward();

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;
			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		uint256[] memory maxAmountsIn = new uint256[](balancerPoolAssets.length);
		maxAmountsIn[balancerPoolAssetIndex] = assetBalance;

		uint256 minBp = _calculateSlippage(assetBalance.mulDivDown(1e18, balancerPool.getRate()));

		// bytes memory userData = abi.encode(1, maxAmountsIn, minBp);
		// console2.logBytes(userData);

		IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
			assets: balancerPoolAssets,
			maxAmountsIn: maxAmountsIn,
			userData: abi.encode(1, maxAmountsIn, minBp), // 1 is enum for EXACT_TOKENS_IN_FOR_BPT_OUT
			fromInternalBalance: false
		});

		depositWrapper.depositSingle(address(reward), address(asset), assetBalance, balancerPoolId, request);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		asset.safeApprove(address(depositWrapper), type(uint256).max);
		_approveSwap();
	}

	function _unapprove() internal {
		asset.safeApprove(address(depositWrapper), 0);
		_unapproveSwap();
	}

	function _unapproveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}
	}

	function _approveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}
	}

	/*///////////////
	/     Errors    /
	///////////////*/

	error WithdrawAndUnwrapFailed();
	error InvalidBalancerPoolAssetIndex();
	error NoRewards();
	error NothingToInvest();
	error BelowMinimum(uint256);
}
