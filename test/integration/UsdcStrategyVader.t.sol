// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/external/usdc/USDC.sol';
import 'src/external/vader/IVaderMinter.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyVader.sol';
import '../TestHelpers.sol';

contract UsdcStrategyVaderTest is Test, TestHelpers {
	Vault vault;
	Strategy strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	USDC constant usdc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8; // Circle
	uint256 usdcWhaleBalance;

	ERC20 constant USDV = ERC20(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe);
	IVaderMinter constant vaderMinter = IVaderMinter(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);
	address constant vaderMinterOwner = 0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9;

	function setUp() public {
		vault = new Vault(usdc, new address[](0), 0);
		strategy = new UsdcStrategyVader(vault, treasury, new address[](0));
		vault.addStrategy(strategy, 100);

		usdcWhaleBalance = usdc.balanceOf(usdcWhale);

		vm.prank(vaderMinterOwner);
		vaderMinter.whitelistPartner(address(strategy), 0, type(uint256).max, type(uint256).max, 0);
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
		vm.assume(amount >= 1e6 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		assertEq(vault.totalAssets(), amount);

		vault.report(strategy);
		assertCloseTo(strategy.totalAssets(), amount, 1); // 0.1%
	}

	function testWithdraw(uint256 amount) public {
		vm.assume(amount >= 1e6 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		vm.startPrank(u1);
		vault.redeem(vault.balanceOf(u1), u1, u1);

		assertCloseTo(usdc.balanceOf(u1), amount, 1); // 0.1%
	}

	function testHarvest(uint256 amount) public {
		vm.assume(amount >= 1e6 && amount <= usdcWhaleBalance);

		depositUsdc(u1, amount, u1);

		vault.report(strategy);

		uint256 startingAssets = strategy.totalAssets();

		assertEq(USDV.balanceOf(treasury), 0);

		vm.warp(block.timestamp + 7 days);

		vault.harvest(strategy);

		assertGt(strategy.totalAssets(), startingAssets);
		assertGt(USDV.balanceOf(treasury), 0);
	}
}
