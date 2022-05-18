// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'src/Vault.sol';
import 'src/external/usdc/USDC.sol';
import 'src/strategies/UsdcStrategyConvexPax.sol';
import 'src/strategies/UsdcStrategyVader.sol';
import 'src/swaps/UsdcSwap.sol';
import '../TestHelpers.sol';

contract UsdcVaultTest is TestHelpers {
	Vault vault;
	ISwap swap;
	UsdcStrategyConvexPax s1;
	UsdcStrategyVader s2;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	USDC constant usdc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8; // Circle
	uint256 usdcWhaleBalance;

	IVaderMinter constant vaderMinter = IVaderMinter(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);
	address constant vaderMinterOwner = 0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9;

	function setUp() public {
		vault = new Vault(usdc, new address[](0), 0);
		swap = new UsdcSwap();
		s1 = new UsdcStrategyConvexPax(vault, treasury, new address[](0), swap);
		s2 = new UsdcStrategyVader(vault, treasury, new address[](0));

		vault.addStrategy(s1, 200);
		vault.addStrategy(s2, 100);

		usdcWhaleBalance = usdc.balanceOf(usdcWhale);

		vm.prank(vaderMinterOwner);
		vaderMinter.whitelistPartner(address(s2), 0, type(uint256).max, type(uint256).max, 0);
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

	function testDepositAndInvest(uint256 amount) public {
		vm.assume(amount >= 1e6 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.reportAll();

		assertCloseTo(s1.totalAssets(), (amount * 2) / 3, 25);
		assertCloseTo(s2.totalAssets(), amount / 3, 1);
	}
}
