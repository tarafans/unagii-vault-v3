// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '../TestHelpers.sol';
import 'src/Vault.sol';
import 'src/strategies/WethStrategyAuraReth.sol';
import 'src/Swap.sol';
import 'src/zaps/WethZap.sol';

contract WethStrategyAuraRethTest is TestHelpers {
	Vault vault;
	WethZap zap;
	Strategy strategy;
	Swap swap;

	address constant u1 = address(0xABCDEF);
	address constant treasury = address(0xAAAAAF);

	ERC20 constant WETH9 = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
	address constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

	// 0.001 WETH
	uint256 internal constant lowerLimit = 1e15;
	// 1000 WETH
	uint256 internal constant upperLimit = 1e21;

	function setUp() public {
		vault = new Vault(WETH9, 0, 0, address(0), address(this), new address[](0));
		strategy = new WethStrategyAuraReth(vault, treasury, address(0), address(this), new address[](0), swap);
		vault.addStrategy(strategy, 100);
		zap = new WethZap(vault);
		Swap = new Swap();

		swap.setRoute(
			BAL,
			address(WETH9),
			Swap.RouteInfo({route: Route.BalancerBatch, info: abi.encode(steps, assets)})
		);
	}

	/*///////////////////
	/      Helpers      /
	///////////////////*/

	function depositWeth(address from, uint256 amount, address receiver) public {
		vm.deal(from, amount);
		vm.startPrank(from);
		zap.depositETH{value: amount}(receiver);
		vm.stopPrank();
	}

	/*/////////////////
	/      Tests      /
	/////////////////*/

	function testDepositAndInvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWeth(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.report(strategy);
		assertCloseTo(strategy.totalAssets(), amount, 10); // 1%
	}

	function testWithdraw(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWeth(u1, amount, u1);

		vault.report(strategy);

		vm.startPrank(u1);
		vault.approve(address(zap), type(uint256).max);
		zap.redeemETH(vault.balanceOf(u1), u1, u1);

		assertCloseTo(address(u1).balance, amount, 10); // 1%
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWeth(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(WETH9.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 14 days);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(WETH9.balanceOf(treasury), 0);
	}
}
