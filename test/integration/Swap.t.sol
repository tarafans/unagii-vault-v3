// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'src/Swap.sol';

contract SwapTest is Test {
	address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

	address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

	address internal constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
	address internal constant PNT = 0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD;

	function testDeploysCorrectly() public {
		Swap swap = new Swap();
		Swap.RouteInfo memory info = swap.getRoute(CVX, USDC);
		assert(info.route == Swap.Route.UniswapV3Path);
	}
}
