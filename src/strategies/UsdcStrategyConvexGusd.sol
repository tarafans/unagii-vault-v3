// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import './UsdcStrategyConvexGen2.sol';

contract UsdcStrategyConvexGusd is UsdcStrategyConvexGen2 {
	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		ISwap _swap
	)
		UsdcStrategyConvexGen2(
			_vault,
			_treasury,
			_authorized,
			IGen2DepositZap(0x64448B78561690B70E17CBE8029a3e5c1bB7136e),
			10,
			_swap
		)
	{}
}
