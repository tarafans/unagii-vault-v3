// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// https://github.com/aurafinance/aura-contracts/blob/main/contracts/interfaces/IRewardPool4626.sol

interface IRewardPool4626 {
	function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

	function deposit(uint256 assets, address receiver) external returns (uint256 shares);

	function asset() external view returns (address);

	function balanceOf(address account) external view returns (uint256);

	function processIdleRewards() external;
}
