// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'forge-std/console.sol';

import 'forge-std/Script.sol';
import 'src/strategies/UsdcStrategyStargate.sol';

contract Deploy is Script {
	Vault vault = Vault(vm.envAddress('USDC_VAULT_ADDRESS'));
	Swap swap = Swap(vm.envAddress('SWAP_ADDRESS'));
	address treasury = vm.envAddress('TREASURY_ADDRESS');
	address[] authorized = vm.envAddress('AUTH_ADDRESSES', ',');

	function run() external {
		vm.startBroadcast(vm.envUint('PRIVATE_KEY'));

		new UsdcStrategyStargate(vault, treasury, authorized, swap);

		vm.stopBroadcast();
	}
}
