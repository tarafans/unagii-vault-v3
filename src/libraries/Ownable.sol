// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Ownable {
	address public owner;
	address public nominatedOwner;

	error Unauthorized();
	error AlreadyRole();
	error NotRole();

	constructor() {
		owner = msg.sender;
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}
}
