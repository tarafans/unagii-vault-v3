// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import './mocks/MockERC20.sol';
import 'src/Vault.sol';

contract VaultTest is Test {
	MockERC20 token;
	Vault vault;

	address u1 = address(0xAAAA);
	address u2 = address(0xAAAB);
	address u3 = address(0xAAAC);

	function setUp() public {
		token = new MockERC20('Mock USD', 'MUSD', 6);
		vault = new Vault(token, new address[](0));
	}

	function testMetadata() public {
		assertEq(vault.name(), 'Unagii Mock USD Vault v3');
		assertEq(vault.symbol(), 'uMUSDv3');
		assertEq(vault.decimals(), 18);
		assertEq(address(vault.asset()), address(token));
	}

	function testDepositAndWithdraw(uint256 amount) public {
		vm.assume(amount > 0);

		token.mint(u1, amount);

		vm.startPrank(u1);

		token.approve(address(vault), type(uint256).max);

		vault.deposit(amount, u1);

		assertEq(vault.balanceOf(u1), amount);
		assertEq(token.balanceOf(address(vault)), amount);
		assertEq(vault.totalAssets(), amount);
	}

	function testCannotDepositZero() public {
		vm.expectRevert(Vault.Zero.selector);
		vault.deposit(0, u1);

		vm.startPrank(u1);

		token.approve(address(vault), type(uint256).max);

		token.mint(u1, 101);
		vault.deposit(100, u1);

		token.mint(address(vault), 100);

		// we are depositing a non-zero amount but this will fail as shares minted rounded down to 0
		vm.expectRevert(Vault.Zero.selector);
		vault.deposit(1, u1);
	}
}
