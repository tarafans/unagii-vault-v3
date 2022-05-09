// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './Vault.sol';

abstract contract Strategy {
	Vault vault;

	error Unauthorized();

	function totalAssets() public view virtual returns (uint256);

	function withdraw(uint256 _assets, address _receiver) external onlyVault returns (uint256 received) {
		return _withdraw(_assets, _receiver);
	}

	function _withdraw(uint256 _assets, address _receiver) internal virtual returns (uint256 received);

	modifier onlyVault() {
		if (msg.sender != address(vault)) revert Unauthorized();
		_;
	}
}
