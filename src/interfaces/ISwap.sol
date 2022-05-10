// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwap {
	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received);
}
