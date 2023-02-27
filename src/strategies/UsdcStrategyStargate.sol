// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import './StrategyStargate.sol';

contract UsdcStrategyStargate is StrategyStargate {
	constructor(
		Vault _vault,
		address _treasury,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap
	) StrategyStargate(_vault, _treasury, _nominatedOwner, _admin, _authorized, _swap, 1, 0) {}
}
