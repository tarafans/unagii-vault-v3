// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://github.com/vetherasset/minter/blob/main/contracts/interfaces/IVaderMinterUpgradeable.sol

interface IVaderMinter {
	function partnerMint(uint256 vAmount, uint256 uAmountMinOut) external returns (uint256 uAmount);

	function whitelistPartner(
		address _partner,
		uint256 _fee,
		uint256 _mintLimit,
		uint256 _burnLimit,
		uint256 _lockDuration
	) external;
}
