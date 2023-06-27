// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "test/integration/WethStrategy.t.sol";
import "src/Vault.sol";
import "src/strategies/WethStrategyAuraReth.sol";
import "src/Swap.sol";
import "src/zaps/WethZap.sol";

contract WethStrategyAuraRethTest is WethStrategyTest {
    function setUp() public override {
        super.setUp();
        strategy = new WethStrategyAuraReth(vault, treasury, address(0), address(this), new address[](0), swap);
        vault.addStrategy(strategy, 100);
    }
}
