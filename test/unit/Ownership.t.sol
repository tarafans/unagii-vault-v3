// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "src/libraries/Ownership.sol";

contract TestOwnership is Ownership {
    constructor(address nominatedOwner, address admin, address[] memory authorized)
        Ownership(nominatedOwner, admin, authorized)
    {}

    function auth() external onlyAuthorized {}
}

contract OwnershipTest is Test {
    TestOwnership private inst;

    address private constant next = address(2);
    address private constant admin = address(3);
    address[] private authorized = [address(4), address(5)];

    function setUp() public {
        inst = new TestOwnership(next, admin, authorized);
    }

    function testConstructor() public {
        assertEq(inst.owner(), address(this));
        assertEq(inst.nominatedOwner(), next);
        assertEq(inst.admin(), admin);
        assertTrue(inst.authorized(authorized[0]));
        assertTrue(inst.authorized(authorized[1]));
    }

    function testNominateOwnership() public {
        // Test unauthorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(1));
        inst.nominateOwnership(address(123));

        // Test authorized
        inst.nominateOwnership(address(123));
        assertEq(inst.nominatedOwner(), address(123));
    }

    function testAcceptOwnership() public {
        // Not nominated
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        inst.acceptOwnership();

        // Authorized
        vm.prank(next);
        inst.acceptOwnership();

        assertEq(inst.owner(), next);
        assertEq(inst.nominatedOwner(), address(0));
    }

    function testSetAdmin() public {
        // Not nominated
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        inst.setAdmin(address(123));

        // Already admin
        vm.expectRevert(Ownership.AlreadyRole.selector);
        inst.setAdmin(admin);

        // Set new admin
        inst.setAdmin(address(123));
        assertEq(inst.admin(), address(123));
    }

    function testAddAuthorized() public {
        // Not authorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        inst.addAuthorized(address(123));

        // Already authorized
        vm.expectRevert(Ownership.AlreadyRole.selector);
        vm.prank(admin);
        inst.addAuthorized(authorized[0]);

        // Admin
        vm.prank(admin);
        inst.addAuthorized(address(123));
        assertTrue(inst.authorized(address(123)));

        // Owner
        inst.addAuthorized(address(456));
        assertTrue(inst.authorized(address(456)));
    }

    function testRemoveAuthorized() public {
        // Not authorized
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        inst.removeAuthorized(authorized[0]);

        // Already authorized
        vm.expectRevert(Ownership.NotRole.selector);
        vm.prank(admin);
        inst.removeAuthorized(address(123));

        // Admin
        vm.prank(admin);
        inst.removeAuthorized(authorized[0]);
        assertTrue(!inst.authorized(authorized[0]));

        // Owner
        inst.removeAuthorized(authorized[1]);
        assertTrue(!inst.authorized(authorized[1]));
    }

    function testOnlyAuthorized() public {
        vm.expectRevert(Ownership.Unauthorized.selector);
        vm.prank(address(123));
        inst.auth();

        // Owner
        inst.auth();

        // Admin
        vm.prank(admin);
        inst.auth();

        // Authorized
        vm.prank(authorized[0]);
        inst.auth();

        vm.prank(authorized[1]);
        inst.auth();
    }
}
