// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './Vault.sol';

/** @dev
 * Strategies have to implement the following virtual functions:
 *
 * totalAssets()
 * _withdraw(uint256, address)
 * _harvest()
 * _invest()
 */
abstract contract Strategy is Ownership {
	Vault public immutable vault;
	ERC20 public immutable asset;

	/// @notice address which performance fees are sent to
	address public treasury;
	/// @dev performance fee sent to treasury
    // TODO: gas might be cheaper (when fee is calculated) using uint256
	uint16 public fee = 1_000;
	uint16 public constant MAX_FEE = 1_000;
	uint16 internal constant FEE_BASIS = 10_000;

	/// @notice used to calculate slippage with SLIP_BASIS
	/// @dev default to 99% (or 1%)
    // TODO: gas might be cheaper (when slip is calculated) using uint256
	uint16 public slip = 990;
	uint16 internal constant SLIP_BASIS = 1_000;

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error Zero();
	error NotVault();
	error InvalidValue();
	error AlreadyValue();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized
	) Ownership(_authorized) {
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

    // TODO: slippage protection on withdraw or slippage protection inside vault contract?
	function withdraw(uint256 _assets, address _receiver) external onlyVault returns (uint256 received) {
		return _withdraw(_assets, _receiver);
	}

	function harvest() external onlyVault {
		_harvest();
	}

    // TODO: slippage protection? min shares or maybe min deposited?
	function invest() external onlyVault {
		_invest();
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setFee(uint16 _fee) external onlyOwner {
		if (_fee > MAX_FEE) revert InvalidValue();
		if (_fee == fee) revert AlreadyValue();
		fee = _fee;
	}

	/*////////////////////////////////////////////
	/      Restricted Functions: onlyAdmins      /
	////////////////////////////////////////////*/

	function setSlip(uint16 _slip) external onlyAdmins {
		if (_slip > SLIP_BASIS) revert InvalidValue();
		if (_slip == slip) revert AlreadyValue();
		slip = _slip;
	}

	/*////////////////////////////
	/      Internal Virtual      /
	////////////////////////////*/

	/// @dev this must handle overflow, i.e. vault trying to withdraw more than what strategy has
    // TODO: maybe return loss on withdraw too? loss = debt - total asset after withdraw 
	function _withdraw(uint256 _assets, address _receiver) internal virtual returns (uint256 received);

	function _harvest() internal virtual;

	function _invest() internal virtual;

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _calculateSlippage(uint256 _amount) internal view returns (uint256) {
		return (_amount * slip) / SLIP_BASIS;
	}

	modifier onlyVault() {
		if (msg.sender != address(vault)) revert NotVault();
		_;
	}
}
