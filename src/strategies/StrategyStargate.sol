// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import '../external/stargate/IStargateRouter.sol';
import '../external/stargate/ILPStaking.sol';
import '../Swap.sol';
import '../Strategy.sol';

abstract contract StrategyStargate is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	IStargateRouter internal constant router = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98);
	ILPStaking internal constant staking = ILPStaking(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b);
	ERC20 internal constant STG = ERC20(0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6);

	/// @dev pid of asset in their router
	uint16 public immutable routerPoolId;
	/// @dev pid of asset in their LP staking contract
	uint256 public immutable stakingPoolId;
	ERC20 public immutable lpToken;

	/// @notice contract used to swap STG rewards to asset
	Swap public swap;

	/*///////////////
	/     Errors    /
	///////////////*/

	error NoRewards();
	error NothingToInvest();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		Swap _swap,
		uint16 _routerPoolId,
		uint256 _stakingPoolId
	) Strategy(_vault, _treasury, _authorized) {
		swap = _swap;
		routerPoolId = _routerPoolId;
		stakingPoolId = _stakingPoolId;
		(address lpTokenAddress, , , ) = staking.poolInfo(stakingPoolId);
		lpToken = ERC20(lpTokenAddress);

		_approve();
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		(uint256 stakedBalance, ) = staking.userInfo(stakingPoolId, address(this));
		return stakedBalance;
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

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 assets = totalAssets();
		if (assets == 0) return 0; // nothing to withdraw;

		uint256 amount = _assets > assets ? assets : _assets;

		// 1. withdraw from staking contract
		staking.withdraw(stakingPoolId, amount);

		// withdraw from stargate router
		received = router.instantRedeemLocal(routerPoolId, amount, _receiver);
	}

	function _harvest() internal override {
		// empty deposit claims rewards withdraw as with all Goose clones
		staking.deposit(stakingPoolId, 0);

		uint256 rewardBalance = STG.balanceOf(address(this));
		if (rewardBalance == 0) revert NoRewards(); // nothing to harvest

		if (fee > 0) {
			uint256 feeAmount = _calculateFee(rewardBalance);
			STG.safeTransfer(treasury, feeAmount);
			rewardBalance -= feeAmount;
		}

		swap.swapTokens(address(STG), address(asset), rewardBalance, 1);

		asset.safeTransfer(address(vault), asset.balanceOf(address(this)));
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		router.addLiquidity(routerPoolId, assetBalance, address(this));

		uint256 balance = lpToken.balanceOf(address(this));

		staking.deposit(stakingPoolId, balance);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit asset into router
		asset.safeApprove(address(router), type(uint256).max);
		// approve deposit lpToken into staking contract
		lpToken.safeApprove(address(staking), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		asset.safeApprove(address(router), 0);
		lpToken.safeApprove(address(staking), 0);

		_unapproveSwap();
	}

	// approve swap rewards to asset
	function _unapproveSwap() internal {
		STG.safeApprove(address(swap), 0);
	}

	// approve swap rewards to asset
	function _approveSwap() internal {
		STG.safeApprove(address(swap), type(uint256).max);
	}
}
