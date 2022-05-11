// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/external/usdc/USDC.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyConvexPax.sol';
import 'src/swaps/UsdcRewardsSwap.sol';
import '../TestHelpers.sol';

contract UsdcStrategyConvexPaxTest is Test, TestHelpers {
	Vault vault;
	ISwap swap;
	Strategy strategy;

	USDC constant usdc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8; // Circle
	uint256 usdcWhaleBalance;

	ERC20 constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	address constant u1 = address(0xAAA1);
	address constant treasury = address(0xAAAF);

	function setUp() public {
		vault = new Vault(usdc, new address[](0), 0);
		swap = new UsdcRewardsSwap();
		strategy = new UsdcStrategyConvexPax(vault, treasury, swap);
		vault.addStrategy(strategy, 100);

		usdcWhaleBalance = usdc.balanceOf(usdcWhale);
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
		usdc.transfer(from, amount);
		vm.startPrank(from);
		usdc.approve(address(vault), type(uint256).max);
		vault.deposit(amount, receiver);
		vm.stopPrank();
	}

	/*/////////////////
	/      Tests      /
	/////////////////*/

	function testDepositAndInvest(uint256 amount) public {
		vm.assume(amount > 0 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.report(strategy);
		assertCloseTo(strategy.totalAssets(), amount, 1); // 1%
	}

	function testWithdraw(uint256 amount) public {
		vm.assume(amount > 0 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		vm.startPrank(u1);
		vault.redeem(vault.balanceOf(u1), u1, u1);

		assertCloseTo(usdc.balanceOf(u1), amount, 1);
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount > 1e6 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(CRV.balanceOf(treasury), 0);
		assertEq(CVX.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 14 days);

		vault.harvest(strategy); // triggers harvest

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(CRV.balanceOf(treasury), 0);
		assertGt(CVX.balanceOf(treasury), 0);
	}
}
