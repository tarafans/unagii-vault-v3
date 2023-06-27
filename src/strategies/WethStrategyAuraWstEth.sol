// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./StrategyAura.sol";

contract WethStrategyAuraWstEth is StrategyAura {
    constructor(
        Vault _vault,
        address _treasury,
        address _nominatedOwner,
        address _admin,
        address[] memory _authorized,
        Swap _swap
    )
        StrategyAura(
            _vault,
            _treasury,
            _nominatedOwner,
            _admin,
            _authorized,
            _swap,
            0x59D66C58E83A26d6a0E35114323f65c3945c89c1,
            0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080,
            1
        )
    {}
}
