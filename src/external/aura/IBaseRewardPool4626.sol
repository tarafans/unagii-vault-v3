// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// https://github.com/aurafinance/convex-platform/blob/ac65176277284b4c988f0e1b12db8d08c48746be/contracts/contracts/BaseRewardPool4626.sol

interface IBaseRewardPool4626 {
    function balanceOf(address) external view returns (uint256);

    function getReward() external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}
