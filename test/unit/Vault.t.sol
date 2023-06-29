// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "src/Vault.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockStrategy.sol";

uint256 constant MAX_TOTAL_DEBT_RATIO = 1_000;

contract VaultTest is Test {
    using FixedPointMathLib for uint256;

    MockERC20 token;
    Vault vault;

    address constant u1 = address(0xAAA1);
    address constant u2 = address(0xAAA2);
    address constant u3 = address(0xAAA3);
    address constant admin = address(100);
    address[] authorized = [address(200), address(300)];

    function setUp() public {
        token = new MockERC20('Mock USD', 'MUSD', 6);
        vault = new Vault(token, 0, 0, address(0), admin, authorized);
    }

    /*///////////////////
    /      Helpers      /
    ///////////////////*/

    function deposit(address from, uint256 amount, address receiver) internal {
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
        assertEq(vault.name(), "Unagii Mock USD Vault v3");
        assertEq(vault.symbol(), "uMUSDv3");
        assertEq(vault.decimals(), 6);
        assertEq(address(vault.asset()), address(token));
    }

    function testConvertToShares() public {
        // Total supply = 0
        assertEq(vault.convertToShares(100), 100);

        // Total supply > 0
        deal(address(token), address(vault), 1000, true);
        deal(address(vault), address(this), 999, true);
        assertEq(vault.convertToShares(100), 99);
    }

    function testConvertToAssets() public {
        // Total supply = 0
        assertEq(vault.convertToAssets(100), 100);

        // Total supply > 0
        deal(address(token), address(vault), 1000, true);
        deal(address(vault), address(this), 900, true);
        assertEq(vault.convertToAssets(90), 100);
    }

    // TODO: preview withdraw
    // TODO: preview redeem
    // TODO: test locked profit
    // TODO: test free assets
    // TODO: test mint / burn block delay
    // TODO: test not authorized withdraw

    function testDepositAndWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);

        deposit(u1, amount, u1);

        assertEq(vault.balanceOf(u1), amount);
        assertEq(token.balanceOf(address(vault)), amount);
        assertEq(vault.totalAssets(), amount);

        vm.startPrank(u1);
        vault.withdraw(amount, u2, u1);
        vm.stopPrank();

        assertEq(vault.totalSupply(), 0);
        assertEq(token.balanceOf(u2), amount);
        assertEq(vault.totalAssets(), 0);
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

    function testDepositToZeroAddress() public {
        token.mint(u1, 100);

        vm.startPrank(u1);
        token.approve(address(vault), 100);

        vm.expectRevert(Vault.Zero.selector);
        vault.deposit(100, address(0));

        vm.stopPrank();
    }

    function testSafeDepositMinShares() public {
        token.mint(u1, 100);

        vm.startPrank(u1);
        token.approve(address(vault), 100);

        vm.expectRevert(abi.encodeWithSelector(Vault.BelowMinimum.selector, 100));
        vault.safeDeposit(100, u1, 1000);

        vm.stopPrank();
    }

    function testMint() public {
        token.mint(u1, 100);

        vm.startPrank(u1);
        token.approve(address(vault), 100);

        // Mint 0 shares
        vm.expectRevert(Vault.Zero.selector);
        vault.mint(0, u1);

        // Mint to address 0
        vm.expectRevert(Vault.Zero.selector);
        vault.mint(100, address(0));

        // Mint
        uint256 assets = vault.mint(100, u1);
        assertGt(assets, 0);

        vm.stopPrank();
    }

    function testSafeMintMaxAssets() public {
        token.mint(u1, 100);

        vm.startPrank(u1);
        token.approve(address(vault), 100);

        vm.expectRevert(abi.encodeWithSelector(Vault.AboveMaximum.selector, 100));
        vault.safeMint(100, u1, 1);

        vm.stopPrank();
    }

    function testWithdraw() public {
        deposit(u1, 100, u1);

        // Withdraw 0
        vm.expectRevert(Vault.Zero.selector);
        vm.prank(u1);
        vault.withdraw(0, u1, u1);

        // Cannot withdraw if not authorized
        vm.expectRevert();
        vm.prank(u3);
        vault.withdraw(1, u3, u1);

        // Withdraw by owner
        vm.prank(u1);
        vault.withdraw(1, u1, u1);

        // Withdraw by approved account
        vm.prank(u1);
        vault.approve(u3, 1);

        vm.prank(u3);
        vault.withdraw(1, u3, u1);
    }

    function testSafeWithdrawMaxShares() public {
        deposit(u1, 100, u1);

        vm.expectRevert(abi.encodeWithSelector(Vault.AboveMaximum.selector, 100));

        vm.prank(u1);
        vault.safeWithdraw(100, u1, u1, 1);
    }

    function testRedeem() public {
        deposit(u1, 100, u1);

        // 0 assets
        vm.expectRevert(Vault.Zero.selector);
        vm.prank(u1);
        vault.redeem(0, u1, u1);

        // Cannot redeem if not authorized
        vm.expectRevert();
        vm.prank(u3);
        vault.redeem(1, u3, u1);

        // redeem by owner
        vm.prank(u1);
        vault.redeem(1, u1, u1);

        // redeem by approved account
        vm.prank(u1);
        vault.approve(u3, 1);

        vm.prank(u3);
        vault.redeem(1, u3, u1);
    }

    function testSafeRedeemMinAssets() public {
        deposit(u1, 100, u1);

        vm.expectRevert(abi.encodeWithSelector(Vault.BelowMinimum.selector, 100));

        vm.prank(u1);
        vault.safeRedeem(100, u1, u1, 1000);
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

        vm.warp(block.timestamp + 12 hours);

        assertEq(vault.lockedProfit(), amount.mulDivUp(1, 2));
        assertEq(vault.freeAssets(), amount.mulDivDown(1, 2));

        vm.warp(block.timestamp + 24 hours);

        assertEq(vault.lockedProfit(), 0);
        assertEq(vault.freeAssets(), amount);
    }

    function testLockedProfitZero(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint240).max);

        Strategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);

        vault.setLockedProfitDuration(0);

        token.mint(address(s1), amount);
        vault.report(s1);

        assertEq(vault.lockedProfit(), 0);
        assertEq(vault.freeAssets(), amount);
        assertEq(vault.totalAssets(), amount);
    }

    function testRemoveStrategy(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint240).max);

        Strategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);

        token.mint(address(vault), amount);
        vault.report(s1);

        vault.removeStrategy(s1, false, 0);

        assertEq(vault.queue().length, 0);
        assertEq(vault.totalAssets(), amount);

        (bool added,,) = vault.strategies(s1);
        assertFalse(added);
    }

    event Report(Strategy indexed strategy, uint256 harvested, uint256 gain, uint256 loss);

    function testReportLoss() public {
        uint256 amount = 100e18;
        uint256 loss = 1e18;

        Strategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);

        token.mint(address(vault), amount);
        vault.report(s1);

        token.burn(address(s1), loss);

        vm.expectEmit(true, true, true, true);
        emit Report(s1, 0, 0, loss);

        vault.report(s1);

        assertEq(vault.totalAssets(), amount - loss);
    }

    event Lend(Strategy indexed strategy, uint256 assets, uint256 slippage);

    function testLendSlippage() public {
        uint256 amount = 100e18;
        uint256 slippage = 1e18;

        MockStrategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);

        s1.setSlippageOnNextInvest(slippage);

        token.mint(address(vault), amount);

        vm.expectEmit(true, true, true, true);
        emit Lend(s1, amount, slippage);

        vault.report(s1);

        assertEq(vault.totalAssets(), amount - slippage);
    }

    event Collect(Strategy indexed strategy, uint256 received, uint256 slippage, uint256 bonus);

    function testCollectSlippage() public {
        uint256 amount = 100e18;
        uint256 slippage = 1e18;

        MockStrategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);
        token.mint(address(vault), amount);
        vault.report(s1);

        s1.setSlippageOnNextWithdraw(slippage);

        vm.expectEmit(true, true, true, true);
        emit Collect(s1, amount - slippage, slippage, 0);

        vault.removeStrategy(s1, false, 0);

        assertEq(vault.totalAssets(), amount - slippage);
    }

    function testCollectBonus() public {
        uint256 amount = 100e18;
        uint256 bonus = 1e18;

        MockStrategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 100);

        deposit(u1, amount, u1);
        vault.report(s1);

        s1.setBonusOnNextWithdraw(bonus);

        vm.startPrank(u1);
        vault.withdraw(amount, u1, u1);
        vm.stopPrank();

        assertEq(token.balanceOf(u1), amount);
        assertEq(vault.totalAssets(), bonus);
    }

    function testSetFloatDebtRatio() public {
        // Not authorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        vault.setFloatDebtRatio(1);

        // Max
        uint256 val = MAX_TOTAL_DEBT_RATIO + 1;
        vm.expectRevert(abi.encodeWithSelector(Vault.AboveMaximum.selector, val));
        vault.setFloatDebtRatio(val);

        // Update
        vault.setFloatDebtRatio(50);
        assertEq(vault.floatDebtRatio(), 50);
    }

    function testFloat(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint240).max);

        vault.setFloatDebtRatio(5);
        MockStrategy s1 = new MockStrategy(vault);
        vault.addStrategy(s1, 95);

        assertEq(vault.totalDebtRatio(), 100);
        assertEq(vault.floatDebtRatio(), 5);

        deposit(u1, amount, u1);
        vault.report(s1);

        uint256 expectedBalance = amount.mulDivDown(95, 100);

        assertEq(token.balanceOf(address(vault)), amount - expectedBalance);
        assertEq(s1.totalAssets(), expectedBalance);

        vault.setFloatDebtRatio(0);

        vault.report(s1);

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(s1.totalAssets(), amount);
        assertEq(vault.totalDebtRatio(), 95);
        assertEq(vault.floatDebtRatio(), 0);
    }

    function testPauseAndUnpause() public {
        // Not authorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        vault.pause();

        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        vault.unpause();

        // Already paused
        vault.pause();
        vm.expectRevert(Vault.AlreadyValue.selector);
        vault.pause();

        // Already unpaused
        vault.unpause();
        vm.expectRevert(Vault.AlreadyValue.selector);
        vault.unpause();

        // Owner
        vault.pause();
        assertTrue(vault.paused());

        vault.unpause();
        assertTrue(!vault.paused());

        // Admin
        vm.startPrank(admin);
        vault.pause();
        vault.unpause();
        vm.stopPrank();

        // Authorized
        for (uint256 i = 0; i < authorized.length; i++) {
            vm.startPrank(authorized[i]);
            vault.pause();
            vault.unpause();
            vm.stopPrank();
        }
    }

    function testSetMaxDeposit() public {
        // Not authorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        vault.setMaxDeposit(0);

        // Update
        vault.setMaxDeposit(1);
        assertEq(vault.maxDeposit(address(0)), 1);

        // No change
        vm.expectRevert(Vault.AlreadyValue.selector);
        vault.setMaxDeposit(1);
    }

    function testTransfer() public {
        deal(address(vault), u1, 100, true);

        uint8 delay = 5;
        vault.setBlockDelay(delay);
        vm.roll(100);

        vm.prank(u1);
        vault.transfer(u2, 10);

        // u1 cannot transfer
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vm.prank(u1);
        vault.transfer(u3, 10);

        // u2 cannot transfer
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vm.prank(u2);
        vault.transfer(u3, 10);

        // Wait block delay
        vm.roll(block.number + delay);
        // u1 can transfer
        vm.prank(u1);
        vault.transfer(u3, 10);

        // u2 cannot transfer to u3
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vm.prank(u2);
        vault.transfer(u3, 10);

        // Wait block delay
        vm.roll(block.number + delay);
        // u2 can transfer to u3
        vm.prank(u2);
        vault.transfer(u3, 10);
    }

    function testTransferFrom() public {
        deal(address(vault), u1, 100, true);

        vm.prank(u1);
        vault.approve(address(this), type(uint256).max);

        vm.prank(u2);
        vault.approve(address(this), type(uint256).max);

        uint8 delay = 5;
        vault.setBlockDelay(delay);
        vm.roll(100);

        vault.transferFrom(u1, u2, 10);

        // u1 cannot transfer
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vault.transferFrom(u1, u3, 10);

        // u2 cannot transfer
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vault.transferFrom(u2, u3, 10);

        // Wait block delay
        vm.roll(block.number + delay);
        // u1 can transfer
        vault.transferFrom(u1, u3, 10);

        // u2 cannot transfer to u3
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        vault.transferFrom(u2, u3, 10);

        // Wait block delay
        vm.roll(block.number + delay);
        // u2 can transfer to u3
        vault.transferFrom(u2, u3, 10);
    }
}
