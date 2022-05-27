// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';

abstract contract USDC is ERC20 {
	function mint(address, uint256) external virtual returns (bool);
}
