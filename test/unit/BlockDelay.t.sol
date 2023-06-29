// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "src/libraries/BlockDelay.sol";

uint8 constant BLOCK_DELAY = 2;
uint8 constant MAX_BLOCK_DELAY = 10;

contract TestBlockDelay is BlockDelay(BLOCK_DELAY) {
    function setBlockDelay(uint8 delay) external {
        _setBlockDelay(delay);
    }

    function updateLastBlock(address addr) external useBlockDelay(addr) {}
}

contract BlockDelayTest is Test {
    TestBlockDelay private testBlockDelay;
    address constant account = address(1);

    function setUp() public {
        testBlockDelay = new TestBlockDelay();
        vm.roll(100);
    }

    function testSetBlockDelayRevertMaxDelay() public {
        vm.expectRevert(BlockDelay.AboveMaxBlockDelay.selector);
        testBlockDelay.setBlockDelay(MAX_BLOCK_DELAY + 1);
    }

    function testSetBlockDelay() public {
        uint8[] memory delays = new uint8[](3);
        delays[0] = 0;
        delays[1] = 1;
        delays[2] = MAX_BLOCK_DELAY;

        for (uint256 i = 0; i < delays.length; i++) {
            testBlockDelay.setBlockDelay(delays[i]);
            assertEq(testBlockDelay.blockDelay(), delays[i]);
        }
    }

    function testUseBlockDelay() public {
        assertEq(testBlockDelay.lastBlock(account), 0, "last block");

        // Test update
        testBlockDelay.updateLastBlock(account);
        assertEq(testBlockDelay.lastBlock(account), block.number);

        // Test revert
        vm.expectRevert(BlockDelay.BeforeBlockDelay.selector);
        testBlockDelay.updateLastBlock(account);

        // Test update again
        vm.roll(testBlockDelay.lastBlock(account) + BLOCK_DELAY);
        testBlockDelay.updateLastBlock(account);
        assertEq(testBlockDelay.lastBlock(account), block.number);
    }

    function testZeroBlockDelay() public {
        testBlockDelay.setBlockDelay(0);

        // Test update
        testBlockDelay.updateLastBlock(account);
        assertEq(testBlockDelay.lastBlock(account), block.number);

        // Test update again
        testBlockDelay.updateLastBlock(account);
        assertEq(testBlockDelay.lastBlock(account), block.number);
    }
}
