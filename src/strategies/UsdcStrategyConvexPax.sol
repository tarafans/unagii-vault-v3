// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './UsdcStrategyConvex.sol';

contract UsdcStrategyConvexPax is UsdcStrategyConvex {
	constructor(
		Vault _vault,
		address _treasury,
		ISwap _swap
	) UsdcStrategyConvex(_vault, _treasury, 57, _swap) {}
}
