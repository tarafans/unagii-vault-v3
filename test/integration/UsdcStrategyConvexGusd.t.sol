// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyConvexGusd.sol';
import 'src/swaps/UsdcSwap.sol';
import '../TestHelpers.sol';

contract UsdcStrategyConvexGusdTest is Test, TestHelpers {
	Vault vault;
	ISwap swap;
	Strategy strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8;

	// 1 USDC
	uint256 internal constant lowerLimit = 1e6;
	// 100 million USDC. beyond this amount tests start to fail due to precision loss (USDC value falling in 3pool)
	uint256 internal constant upperLimit = 1e14;

	ERC20 constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	function setUp() public {
		vault = new Vault(USDC, new address[](0), 0);
		swap = new UsdcSwap();
		strategy = new UsdcStrategyConvexGusd(vault, treasury, new address[](0), swap);
		vault.addStrategy(strategy, 100);
	}

	/*///////////////////
	/      Helpers      /
	///////////////////*/

	function depositUsdc(
		address from,
		uint256 amount,
		address receiver
	) public {
		vm.prank(usdcWhale);
		USDC.transfer(from, amount);
		vm.startPrank(from);
		USDC.approve(address(vault), type(uint256).max);
		vault.deposit(amount, receiver);
		vm.stopPrank();
	}

	/*/////////////////
	/      Tests      /
	/////////////////*/

	function testDepositAndInvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositUsdc(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.report(strategy);
		assertCloseTo(strategy.totalAssets(), amount, 10); // 1%
	}

	function testWithdraw(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		vm.startPrank(u1);
		vault.redeem(vault.balanceOf(u1), u1, u1);

		assertCloseTo(USDC.balanceOf(u1), amount, 1); // 0.1%
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(CRV.balanceOf(treasury), 0);
		assertEq(CVX.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 14 days);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(CRV.balanceOf(treasury), 0);
		assertGt(CVX.balanceOf(treasury), 0);
	}
}
