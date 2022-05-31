//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://curve.readthedocs.io/exchange-pools.html#metapools
// for pre-factory curve metapools. main differences are one zap per pool and lpToken is separate ERC20

abstract contract IGen2MetaPool {
	function exchange(
		int128,
		int128,
		uint256,
		uint256
	) external virtual returns (uint256);

	function exchange_underlying(
		int128,
		int128,
		uint256,
		uint256
	) external virtual returns (uint256);

	function add_liquidity(uint256[2] memory, uint256) external virtual returns (uint256);

	function get_dy_underlying(
		int128 i,
		int128 j,
		uint128 dx
	) external view virtual returns (uint256);

	function base_virtual_price() external view virtual returns (uint256);

	function calc_withdraw_one_coin(uint256 _burn_amount, int128 _i) external view virtual returns (uint256);

	function coins(uint256) external view virtual returns (address);
}
