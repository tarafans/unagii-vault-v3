// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

/// https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8#code

interface IAsset {

}

interface IVault {
	struct JoinPoolRequest {
		IAsset[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	function getPoolTokens(
		bytes32 poolId
	) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

	function getPoolTokenInfo(
		bytes32 poolId,
		address token
	) external view returns (uint256 cash, uint256 managed, uint256 lastChangedBlock, address assetManager);

	function queryExit(
		bytes32 poolId,
		address sender,
		address recipient,
		IVault.ExitPoolRequest memory request
	) external returns (uint256 bptIn, uint256[] memory amountsOut);

	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		IAsset assetIn;
		IAsset assetOut;
		uint256 amount;
		bytes userData;
	}

	function swap(
		SingleSwap memory singleSwap,
		FundManagement memory funds,
		uint256 limit,
		uint256 deadline
	) external returns (uint256 amountCalculated);

	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}
}
