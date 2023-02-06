// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'forge-std/console.sol';

import 'forge-std/Script.sol';
import 'src/strategies/UsdcStrategyStargate.sol';
import 'src/strategies/WethStrategyConvexStEth.sol';
import 'src/zaps/WethZap.sol';

contract Deploy is Script {
	Swap swap = Swap(vm.envAddress('SWAP_ADDRESS'));
	address treasury = vm.envAddress('TREASURY_ADDRESS');
	address multisig = vm.envAddress('MULTISIG_ADDRESS');
	address timeLock = vm.envAddress('TIMELOCK_ADDRESS');
	address[] authorized = vm.envAddress('AUTH_ADDRESSES', ',');

	ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	ERC20 constant WETH9 = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	// ERC20 constant WBTC = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

	uint8 constant delay = 5;

	function run() external {
		vm.startBroadcast(vm.envUint('PRIVATE_KEY'));

		Vault usdcVault = new Vault(USDC, authorized, delay);

		UsdcStrategyStargate usdcStrategy = new UsdcStrategyStargate(usdcVault, treasury, authorized, swap);
		usdcVault.addStrategy(usdcStrategy, 100);

		usdcVault.setMaxDeposit(1e12); // 1 million USDC

		Vault wethVault = new Vault(WETH9, authorized, delay);
		WethStrategyConvexStEth wethStrategy = new WethStrategyConvexStEth(wethVault, treasury, authorized, swap);
		wethVault.addStrategy(wethStrategy, 100);
		new WethZap(wethVault);

		wethVault.setMaxDeposit(1000e18); // 1000 ETH

		usdcVault.setAdmin(multisig);
		usdcVault.nominateOwnership(timeLock);

		usdcStrategy.setAdmin(multisig);
		usdcStrategy.nominateOwnership(timeLock);

		wethVault.setAdmin(multisig);
		wethVault.nominateOwnership(timeLock);

		wethStrategy.setAdmin(multisig);
		wethStrategy.nominateOwnership(timeLock);

		vm.stopBroadcast();
	}
}

contract Setup is Script {
	address multisig = vm.envAddress('MULTISIG_ADDRESS');
	address timeLock = vm.envAddress('TIMELOCK_ADDRESS');

	function run() external {
		vm.startBroadcast(vm.envUint('PRIVATE_KEY'));

		WethStrategyConvexStEth wethStrat = WethStrategyConvexStEth(
			payable(vm.envAddress('WETH_STRATEGY_CONVEX_STETH'))
		);
		wethStrat.setAdmin(multisig);
		wethStrat.nominateOwnership(timeLock);

		Vault wethVault = Vault(vm.envAddress('WETH_VAULT'));
		wethVault.nominateOwnership(timeLock);

		vm.stopBroadcast();
	}
}

contract Deposit is Script {
	ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	ERC20 constant WETH9 = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

	address me = 0x7c5D6df0646aD1Dc77FFB52E2430bE779729ed69;

	function run() external {
		vm.startBroadcast(vm.envUint('MY_PRIVATE_KEY'));

		Vault wethVault = Vault(vm.envAddress('WETH_VAULT'));

		uint256 wethBal = WETH9.balanceOf(me);
		WETH9.approve(address(wethVault), wethBal);

		wethVault.deposit(wethBal, me);

		Vault usdcVault = Vault(vm.envAddress('USDC_VAULT'));
		uint256 usdcBal = USDC.balanceOf(me);
		USDC.approve(address(usdcVault), usdcBal);

		usdcVault.deposit(usdcBal, me);

		vm.stopBroadcast();
	}
}
