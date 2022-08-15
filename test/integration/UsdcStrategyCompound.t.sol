// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'solmate/tokens/ERC20.sol';
import 'src/Vault.sol';
import 'src/strategies/UsdcStrategyCompound.sol';
import 'src/Swap.sol';
import '../TestHelpers.sol';

contract UsdcStrategyCompoundTest is Test, TestHelpers {
	Vault vault;
	Swap swap;
	StrategyCompound strategy;

	address constant u1 = address(0xABCD);
	address constant treasury = address(0xAAAF);

	ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address constant usdcWhale = 0x55FE002aefF02F77364de339a1292923A15844B8;

	// 1 USDC
	uint256 internal constant lowerLimit = 1e6;
	// 10 million USDC
	uint256 internal constant upperLimit = 10e12;

	ERC20 constant COMP = ERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
	address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	function setUp() public {
		vault = new Vault(USDC, new address[](0), 0);
		swap = new Swap();

		address[] memory path = new address[](3);
		path[0] = address(COMP);
		path[1] = WETH;
		path[2] = address(USDC);

		swap.setRoute(
			address(COMP),
			address(USDC),
			Swap.RouteInfo({route: Swap.Route.UniswapV2, info: abi.encode(path)})
		);

		strategy = new UsdcStrategyCompound(vault, treasury, new address[](0), swap);
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

	// some random 1 USDC transfer to update cToken.getAccountSnapShot()
	function cTokenUpdate() public {
		ICerc20 cTokenUSDC = ICerc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
		vm.startPrank(usdcWhale);
		USDC.approve(address(cTokenUSDC), type(uint256).max);
		cTokenUSDC.mint(1e6);
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

		(uint256 supplied, uint256 borrowed, , uint256 safeCol, uint256 collateralRatio) = strategy.getHealth();

		assertCloseTo(supplied - borrowed, amount, 1); // 0.1%
		assertLe(collateralRatio, safeCol);
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

		assertEq(COMP.balanceOf(treasury), 0);

		vm.roll(block.number + 100_000);

		vault.harvest(strategy);

		(uint256 supplied, uint256 borrowed, , uint256 safeCol, uint256 collateralRatio) = strategy.getHealth();

		assertGt(supplied - borrowed, startingAssets);
		assertGt(COMP.balanceOf(treasury), 0);
		assertLe(collateralRatio, safeCol);
	}
}
