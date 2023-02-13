// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'forge-std/Test.sol';
import 'src/Staking.sol';
import '../mocks/MockERC20.sol';

contract StakingTest is Test {
	MockERC20 asset;
	MockERC20 reward;

	Staking staking;

	address u1 = address(0xAAA1);
	address u2 = address(0xAAA2);

	function setUp() public {
		asset = new MockERC20('Mock Asset', 'mAsset', 18);
		reward = new MockERC20('Mock Reward', 'mReward', 18);
		staking = new Staking(asset, reward);
	}

	function deposit(address from, uint256 amount) internal {
		asset.mint(from, amount);

		vm.startPrank(from);
		asset.approve(address(staking), amount);
		staking.deposit(amount);
		vm.stopPrank();
	}

	function testDepositAndWithdraw(uint256 amount) public {
		vm.assume(amount > 0 && amount < type(uint128).max);

		assertEq(staking.totalShares(), 0);
		assertEq(staking.shares(u1), 0);
		assertEq(staking.lockedAssets(u1), 0);

		deposit(u1, amount);

		assertEq(staking.shares(u1), amount);
		assertEq(staking.totalShares(), amount);
		assertEq(staking.lockedAssets(u1), amount);
		assertEq(staking.freeAssets(u1), 0);

		vm.warp(block.timestamp + 7 days);

		assertEq(staking.lockedAssets(u1), 0);
		assertEq(staking.freeAssets(u1), amount);

		vm.prank(u1);
		staking.withdraw(amount);

		assertEq(staking.shares(u1), 0);
		assertEq(staking.totalShares(), 0);
		assertEq(asset.balanceOf(u1), amount);
	}
}
