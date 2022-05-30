// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/Vault.sol';
import 'src/strategies/WbtcStrategyConvexPbtc.sol';
import 'src/swaps/WbtcSwap.sol';
import '../TestHelpers.sol';

contract WbtcStrategyConvexPbtcTest is Test, TestHelpers {
	Vault vault;
	ISwap swap;
	Strategy strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	ERC20 constant WBTC = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
	address constant wbtcWhale = 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656; // Aave

	// 0.1 WBTC,
	uint256 internal constant lowerLimit = 1e7;
	// 1000 WBTC
	uint256 internal constant upperLimit = 1e11;

	ERC20 constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
	ERC20 constant PNT = ERC20(0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD);

	function setUp() public {
		vault = new Vault(WBTC, new address[](0), 0);
		swap = new WbtcSwap();
		strategy = new WbtcStrategyConvexPbtc(vault, treasury, new address[](0), swap);
		vault.addStrategy(strategy, 100);
	}

	/*///////////////////
	/      Helpers      /
	///////////////////*/

	function depositWbtc(
		address from,
		uint256 amount,
		address receiver
	) public {
		vm.prank(wbtcWhale);
		WBTC.transfer(from, amount);
		vm.startPrank(from);
		WBTC.approve(address(vault), type(uint256).max);
		vault.deposit(amount, receiver);
		vm.stopPrank();
	}

	/*/////////////////
	/      Tests      /
	/////////////////*/

	function testDepositAndInvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWbtc(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.report(strategy);
		assertCloseTo(strategy.totalAssets(), amount, 10); // 1%
	}

	function testWithdraw(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWbtc(u1, amount, u1);

		vault.report(strategy);

		vm.startPrank(u1);
		vault.redeem(vault.balanceOf(u1), u1, u1);

		assertCloseTo(WBTC.balanceOf(u1), amount, 10); // 1%
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWbtc(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(CRV.balanceOf(treasury), 0);
		assertEq(CVX.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 14 days);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(CRV.balanceOf(treasury), 0);
		assertGt(CVX.balanceOf(treasury), 0);
		assertGt(PNT.balanceOf(treasury), 0);
	}
}
