// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/external/usdc/USDC.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyConvexPax.sol';

contract UsdcStrategyConvexPaxTest is Test {
	Vault vault;

	USDC private constant USDC = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

	function setUp() public {
		vault = new Vault(USDC, []);
	}
}
