// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './UsdcStrategyConvex.sol';

contract UsdcStrategyConvexPax is UsdcStrategyConvex {
	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		ISwap _swap
	) UsdcStrategyConvex(_vault, _treasury, _authorized, 57, _swap) {}
}
