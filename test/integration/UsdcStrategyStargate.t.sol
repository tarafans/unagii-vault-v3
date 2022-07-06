// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyStargate.sol';
import 'src/Swap.sol';
import '../TestHelpers.sol';

contract UsdcStrategyStargateTest is Test, TestHelpers {
	Vault vault;
	Swap swap;
	Strategy strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8;

	// 1 USDC
	uint256 internal constant lowerLimit = 1e6;
	uint256 internal constant upperLimit = 1e12;

	ERC20 constant STG = ERC20(0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6);

	function setUp() public {
		vault = new Vault(USDC, new address[](0), 0);
		swap = new Swap();

		address[] memory path = new address[](3);
		path[0] = address(STG);
		path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
		path[2] = address(USDC);

		swap.setRoute(
			address(STG),
			address(USDC),
			Swap.RouteInfo({route: Swap.Route.UniswapV2, info: abi.encode(path)})
		);

		strategy = new UsdcStrategyStargate(vault, treasury, new address[](0), swap);
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
		assertCloseTo(strategy.totalAssets(), amount, 1); // 0.1%
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

		assertEq(STG.balanceOf(treasury), 0);

		vm.roll(block.number + 300_000);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(STG.balanceOf(treasury), 0);
	}
}
