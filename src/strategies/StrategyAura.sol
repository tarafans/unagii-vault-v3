// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import '../Swap.sol';
import '../Strategy.sol';
import '../external/aura/IRewardPoolDepositWrapper.sol';
import '../external/convex/IBaseRewardPool.sol';

abstract contract StrategyAura is Strategy {
	/// @notice contract used to swap BAL & AURA rewards to asset
	Swap public swap;

	IRewardPoolDepositWrapper public constant rewardPoolDepositWrapper =
		IRewardPoolDepositWrapper(0xB188b1CB84Fb0bA13cb9ee1292769F903A9feC59);

	IBaseRewardPool public immutable reward;
	bytes32 public immutable balancerPoolId;

	ERC20 public constant BAL = ERC20(0xba100000625a3754423978a60c9317c58a424e3D);
	ERC20 public constant AURA = ERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);

	constructor(
		Vault _vault,
		address _treasury,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap,
		IBaseRewardPool _reward,
		bytes32 _balancerPoolId
	) Strategy(_vault, _treasury, _nominatedOwner, _admin, _authorized) {
		swap = _swap;

		reward = _reward;
		balancerPoolId = _balancerPoolId;

		_approve();
	}

	function totalAssets() public view override returns (uint256 assets) {}

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

	function _withdraw(uint256 _assets) internal override returns (uint256 received) {}

	function _harvest() internal override {}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		IVault.JoinPoolRequest request = IVault.JoinPoolRequest({
			assets: // address
			maxAmountsIn: // ??
			userData:
			fromInternalBalance: 
		})

		rewardPoolDepositWrapper.depositSingle(reward, address(asset), assetBalance, balancerPoolId, request);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit asset into wrapper
		asset.safeApprove(address(rewardPoolDepositWrapper), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		asset.safeApprove(address(rewardPoolDepositWrapper), 0);

		_unapproveSwap();
	}

	// approve swap rewards to asset
	function _unapproveSwap() internal {
		BAL.safeApprove(address(swap), 0);
		AURA.safeApprove(address(swap), 0);
	}

	// approve swap rewards to asset
	function _approveSwap() internal {
		BAL.safeApprove(address(swap), type(uint256).max);
		AURA.safeApprove(address(swap), type(uint256).max);
	}

	/*///////////////
	/     Errors    /
	///////////////*/

	error NoRewards();
	error NothingToInvest();
	error BelowMinimum(uint256);
}
