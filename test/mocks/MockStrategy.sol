// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import 'src/Strategy.sol';

contract MockStrategy is Strategy {
	using SafeTransferLib for ERC20;

	constructor(Vault _vault) Strategy(_vault, address(0), new address[](0)) {}

	function totalAssets() public view override returns (uint256) {
		return asset.balanceOf(address(this));
	}

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 total = totalAssets();
		received = _assets > total ? total : _assets;

		asset.safeTransfer(_receiver, received);
	}

	function _harvest() internal override {}

	function _invest() internal override {}
}
