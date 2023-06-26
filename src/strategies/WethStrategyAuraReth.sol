// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import './StrategyAura.sol';

contract WethStrategyAuraReth is StrategyAura {
	constructor(
		Vault _vault,
		address _treasury,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap
	)
		StrategyAura(
			_vault,
			_treasury,
			_nominatedOwner,
			_admin,
			_authorized,
			_swap,
			0xDd1fE5AD401D4777cE89959b7fa587e569Bf125D,
			0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112,
			1
		)
	{}
}
