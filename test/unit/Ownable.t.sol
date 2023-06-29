// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "src/libraries/Ownable.sol";

contract TestOwnable is Ownable {}

contract OwnershipTest is Test {
    TestOwnable private inst;

    address private constant next = address(2);

    function setUp() public {
        inst = new TestOwnable();
    }

    function testConstructor() public {
        assertEq(inst.owner(), address(this));
        assertEq(inst.nominatedOwner(), address(0));
    }

    function testNominateOwnership() public {
        // Test unauthorized
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(address(1));
        inst.nominateOwnership(next);

        // Test authorized
        inst.nominateOwnership(next);
        assertEq(inst.nominatedOwner(), next);
    }

    function testAcceptOwnership() public {
        // Not nominated
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(address(123));
        inst.acceptOwnership();

        // Authorized
        inst.nominateOwnership(next);

        vm.prank(next);
        inst.acceptOwnership();

        assertEq(inst.owner(), next);
        assertEq(inst.nominatedOwner(), address(0));
    }
}
