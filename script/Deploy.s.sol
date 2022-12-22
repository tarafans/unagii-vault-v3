// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'forge-std/console.sol';

import 'forge-std/Script.sol';
import 'src/strategies/UsdcStrategyStargate.sol';
import 'src/strategies/WethStrategyConvexStEth.sol';
import 'src/strategies/WbtcStrategyConvexSbtc.sol';
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

		// Vault wbtcVault = new Vault(WBTC, authorized, delay);
		// WbtcStrategyConvexSbtc wbtcStrategy = new WbtcStrategyConvexSbtc(wbtcVault, treasury, authorized, swap);
		// wbtcVault.addStrategy(wbtcStrategy, 100);

		vm.stopBroadcast();
	}
}
