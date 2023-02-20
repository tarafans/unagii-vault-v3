// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'src/Staking.sol';
import 'src/libraries/Ownership.sol';

abstract contract Treasury is Ownership {
	/// @notice staking contract where where rewards are sent to
	Staking public immutable staking;
	/// @notice reward token sent to staking contract
	ERC20 public immutable reward;

	constructor(Staking _staking, address[] memory _authorized) Ownership(_authorized) {
		staking = _staking;
		reward = staking.reward();
	}

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	function withdraw(uint256 _assets) external onlyOwner returns (uint256 received) {
		return _withdraw(_assets);
	}

	/*////////////////////////////////
	/      Authorized Functions      /
	////////////////////////////////*/

	function harvest() external onlyAuthorized {
		_harvest();
		staking.updateTotalRewards();
	}

	function invest() external onlyAuthorized {
		_invest();
	}

	/*////////////////////////////
	/      Internal Virtual      /
	////////////////////////////*/

	/// @dev this must 1. collect yield and 2. convert into rewards if necessary 3. send reward to staking contract
	function _harvest() internal virtual;

	function _withdraw(uint256 _assets) internal virtual returns (uint256 received);

	function _invest() internal virtual;
}
