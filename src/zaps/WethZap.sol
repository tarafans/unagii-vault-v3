// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/WETH.sol';
import 'solmate/utils/SafeTransferLib.sol';
import '../Vault.sol';

/// @notice contract to deposit/withdraw native tokens, e.g. ETH/WETH, MATIC/WMATIC
contract WethZap {
	using SafeTransferLib for WETH;

	Vault public immutable vault;
	WETH public immutable WETH9;

	constructor(Vault _vault) {
		vault = _vault;
		WETH9 = WETH(payable(address(_vault.asset())));
	}

	receive() external payable {}

	function safeDepositETH(address _receiver, uint256 _minShares) external payable returns (uint256 shares) {
		WETH9.deposit{value: msg.value}();
		WETH9.safeApprove(address(vault), msg.value);

		return vault.safeDeposit(msg.value, _receiver, _minShares);
	}

	function depositETH(address _receiver) external payable returns (uint256 shares) {
		WETH9.deposit{value: msg.value}();
		WETH9.safeApprove(address(vault), msg.value);

		return vault.deposit(msg.value, _receiver);
	}

	/// @notice user has to approve zap using vault share tokens
	function safeRedeemETH(
		uint256 _shares,
		address _receiver,
		address _owner,
		uint256 _maxShares
	) external returns (uint256 assets) {
		assets = vault.safeRedeem(_shares, address(this), _owner, _maxShares);
		WETH9.withdraw(assets);
		SafeTransferLib.safeTransferETH(_receiver, assets);
	}

	/// @notice user has to approve zap using vault share tokens
	function redeemETH(
		uint256 _shares,
		address _receiver,
		address _owner
	) external returns (uint256 assets) {
		assets = vault.redeem(_shares, address(this), _owner);
		WETH9.withdraw(assets);
		SafeTransferLib.safeTransferETH(_receiver, assets);
	}
}
