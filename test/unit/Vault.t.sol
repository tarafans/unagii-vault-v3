// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'solmate/utils/FixedPointMathLib.sol';
import 'src/Vault.sol';
import '../mocks/MockERC20.sol';
import '../mocks/MockStrategy.sol';

contract VaultTest is Test {
	MockERC20 token;
	Vault vault;
	using FixedPointMathLib for uint256;

	address u1 = address(0xAAA1);

	// address u2 = address(0xAAA1);
	// address u3 = address(0x0003);

	function setUp() public {
		token = new MockERC20('Mock USD', 'MUSD', 6);
		vault = new Vault(token, new address[](0), 0);
	}

	/*///////////////////
	/      Helpers      /
	///////////////////*/

	function deposit(
		address from,
		uint256 amount,
		address receiver
	) internal {
		token.mint(from, amount);
		vm.startPrank(from);
		token.approve(address(vault), type(uint256).max);
		vault.deposit(amount, receiver);
		vm.stopPrank();
	}

	/*/////////////////
	/      Tests      /
	/////////////////*/

	function testMetadata() public {
		assertEq(vault.name(), 'Unagii Mock USD Vault v3');
		assertEq(vault.symbol(), 'uMUSDv3');
		assertEq(vault.decimals(), 6);
		assertEq(address(vault.asset()), address(token));
	}

	function testDepositAndWithdraw(uint256 amount) public {
		vm.assume(amount > 0);

		deposit(u1, amount, u1);

		assertEq(vault.balanceOf(u1), amount);
		assertEq(token.balanceOf(address(vault)), amount);
		assertEq(vault.totalAssets(), amount);
	}

	function testCannotDepositZero() public {
		vm.expectRevert(Vault.Zero.selector);
		vault.deposit(0, u1);

		deposit(u1, 100, u1);
		// mint shares for vault, increasing share price
		token.mint(address(vault), 100);

		// revert as shares minted rounded down to 0
		vm.expectRevert(Vault.Zero.selector);
		vault.deposit(1, u1);
	}

	function testReportAll(uint256 amount) public {
		vm.assume(amount > 0 && amount < type(uint248).max);

		Strategy s1 = new MockStrategy(vault);
		Strategy s2 = new MockStrategy(vault);

		vault.addStrategy(s1, 200);
		vault.addStrategy(s2, 100);

		token.mint(address(vault), amount);

		vault.reportAll();

		assertEq(s1.totalAssets(), (amount * 2) / 3);
		assertEq(s2.totalAssets(), amount / 3);
	}

	function testLockedProfit(uint256 amount) public {
		vm.assume(amount > 0 && amount < type(uint240).max);

		Strategy s1 = new MockStrategy(vault);
		vault.addStrategy(s1, 100);

		token.mint(address(s1), amount);
		vault.report(s1);

		assertEq(vault.lockedProfit(), amount);
		assertEq(vault.freeAssets(), 0);
		assertEq(vault.totalAssets(), amount);

		vm.warp(block.timestamp + 3 hours);

		assertEq(vault.lockedProfit(), amount.mulDivUp(1, 2));
		assertEq(vault.freeAssets(), amount.mulDivDown(1, 2));

		vm.warp(block.timestamp + 6 hours);

		assertEq(vault.lockedProfit(), 0);
		assertEq(vault.freeAssets(), amount);
	}
}
