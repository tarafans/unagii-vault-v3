// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import 'src/Strategy.sol';
import './MockERC20.sol';

contract MockStrategy is Strategy {
	using SafeTransferLib for ERC20;

	// to simulate slippage and gain calculations
	uint256 slippageOnNextInvest;

	constructor(Vault _vault) Strategy(_vault, address(0), new address[](0)) {}

	function totalAssets() public view override returns (uint256) {
		return asset.balanceOf(address(this));
	}

	function setSlippageOnNextInvest(uint256 _slippageOnNextInvest) external {
		slippageOnNextInvest = _slippageOnNextInvest;
	}

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		asset.safeTransfer(_receiver, _assets);
		return _assets;
	}

	function _harvest() internal override returns (uint256) {}

	function _invest() internal override {
		if (slippageOnNextInvest == 0) return;

		// burn during _invest to simulate slippage
		MockERC20 mockAsset = MockERC20(address(asset));
		mockAsset.burn(address(this), slippageOnNextInvest);

		slippageOnNextInvest = 0;
	}
}
