// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// https://curve.readthedocs.io/factory-deposits.html

interface IDepositZap {
	function calc_withdraw_one_coin(
		address pool,
		uint256 amount,
		int128 i
	) external view returns (uint256);

	function calc_token_amount(
		address pool,
		uint256[4] memory amounts,
		bool is_deposit
	) external view returns (uint256);

	function add_liquidity(
		address _pool,
		uint256[4] memory _deposit_amounts,
		uint256 min_mint_amount
	) external returns (uint256);

	function remove_liquidity_imbalance(
		address _pool,
		uint256[4] memory _amounts,
		uint256 _max_burn_amount
	) external returns (uint256);

	function remove_liquidity_imbalance(
		address _pool,
		uint256[4] memory _amounts,
		uint256 _max_burn_amount,
		address _receiver
	) external returns (uint256);

	function remove_liquidity(address _pool, uint256 _burn_amount) external returns (uint256);

	function remove_liquidity_one_coin(
		address _pool,
		uint256 _burn_amount,
		int128 _i,
		uint256 _min_amount,
		address _receiver
	) external returns (uint256);
}
