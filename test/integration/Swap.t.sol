// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'src/Swap.sol';

contract SwapTest is Test {
	address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	function testDeploysCorrectly() public {
		Swap swap = new Swap();
		Swap.RouteInfo memory info = swap.getRoute(CVX, USDC);
		assert(info.route == Swap.Route.UniswapV3Path);
	}
}
