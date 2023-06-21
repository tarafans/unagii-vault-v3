// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import {IVault} from '../balancer/IVault.sol';

/// https://github.com/aurafinance/aura-contracts/blob/main/contracts/peripheral/RewardPoolDepositWrapper.sol

interface IRewardPoolDepositWrapper {
	function depositSingle(
		address _rewardPoolAddress,
		address _inputToken,
		uint256 _inputAmount,
		bytes32 _balancerPoolId,
		IVault.JoinPoolRequest memory _request
	) external;
}
