// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IPool {
	function deltaCredit() external view returns (uint256);
}
