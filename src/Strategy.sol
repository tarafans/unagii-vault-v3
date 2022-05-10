// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './Vault.sol';

/** @dev
 * Strategies must implement the following virtual functions:
 *
 * totalAssets()
 * _withdraw(uint256, address)
 * _harvest()
 * _invest()
 *
 */
abstract contract Strategy {
	Vault public immutable vault;
	ERC20 public immutable asset;

	address treasury;

	uint16 public fee = 1_000;
	uint16 constant MAX_FEE = 1_000;
	uint16 constant FEE_BASIS = 10_000;

	uint16 public slip = 10;
	uint16 constant MAX_SLIP_FACTOR = 50;
	uint16 constant SLIP_BASIS = 1_000;

	error Unauthorized();

	constructor(Vault _vault, address _treasury) {
		vault = _vault;
		asset = vault.asset();

		treasury = _treasury;
	}

	/*//////////////////////////
	/      Public Virtual      /
	//////////////////////////*/

	/// @notice amount of 'asset' currently managed by strategy
	function totalAssets() public view virtual returns (uint256);

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyVault      /
	///////////////////////////////////////////*/

	function withdraw(uint256 _assets, address _receiver) external onlyVault returns (uint256 received) {
		return _withdraw(_assets, _receiver);
	}

	function harvest() external onlyVault {
		_harvest();
	}

	function invest() external onlyVault {
		_invest();
	}

	/*////////////////////////////
	/      Internal Virtual      /
	////////////////////////////*/

	/// @dev this must handle overflow, i.e. vault trying to withdraw more than what strategy has
	function _withdraw(uint256 _assets, address _receiver) internal virtual returns (uint256 received);

	function _harvest() internal virtual;

	function _invest() internal virtual;

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _calculateSlippage(uint256 _amount) internal view returns (uint256) {
		return (_amount * (SLIP_BASIS - slip)) / SLIP_BASIS;
	}

	modifier onlyVault() {
		if (msg.sender != address(vault)) revert Unauthorized();
		_;
	}
}
