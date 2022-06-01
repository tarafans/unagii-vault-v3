// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/Vault.sol';
import 'src/strategies/WethStrategyConvexStEth.sol';
import 'src/Swap.sol';
import '../TestHelpers.sol';

contract WethStrategyConvexStEthTest is Test, TestHelpers {
	Vault vault;
	Swap swap;
	Strategy strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	ERC20 constant WETH9 = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant wethWhale = 0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0;

	// 0.01 WETH
	uint256 internal constant lowerLimit = 1e16;
	// 1000 WETH
	uint256 internal constant upperLimit = 1e21;

	ERC20 constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
	ERC20 constant LDO = ERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

	function setUp() public {
		vault = new Vault(WETH9, new address[](0), 0);
		swap = new Swap();
		strategy = new WethStrategyConvexStEth(vault, treasury, new address[](0), swap);
		vault.addStrategy(strategy, 100);
	}

	/*///////////////////
	/      Helpers      /
	///////////////////*/

	function depositWeth(
		address from,
		uint256 amount,
		address receiver
	) public {
		vm.prank(wethWhale);
		WETH9.transfer(from, amount);
		vm.startPrank(from);
		WETH9.approve(address(vault), type(uint256).max);
		vault.deposit(amount, receiver);
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
		vault.redeem(vault.balanceOf(u1), u1, u1);

		assertCloseTo(WETH9.balanceOf(u1), amount, 10); // 1%
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount >= lowerLimit && amount <= upperLimit);

		depositWeth(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(CRV.balanceOf(treasury), 0);
		assertEq(CVX.balanceOf(treasury), 0);
		assertEq(LDO.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 14 days);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(CRV.balanceOf(treasury), 0);
		assertGt(CVX.balanceOf(treasury), 0);
		assertGt(LDO.balanceOf(treasury), 0);
	}
}
