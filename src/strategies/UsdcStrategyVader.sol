// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import '../external/curve/IFactoryDepositZap.sol';
import '../external/curve/IFactoryMetaPool.sol';
import '../external/vader/IVaderMinter.sol';
import '../external/vader/IStakingRewards.sol';
import '../Strategy.sol';

contract UsdcStrategyVader is Strategy {
	using SafeTransferLib for ERC20;
	using SafeTransferLib for IFactoryMetaPool;

	IFactoryDepositZap private constant zap = IFactoryDepositZap(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
	IFactoryMetaPool private constant pool = IFactoryMetaPool(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
	IVaderMinter private constant minter = IVaderMinter(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);
	IStakingRewards private constant reward = IStakingRewards(0x2413e4594aadE7513AB6Dc43209D4C312cC35121);

	ERC20 private constant VADER = ERC20(0x2602278EE1882889B946eb11DC0E810075650983);
	ERC20 private constant USDV = ERC20(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe);

	int128 internal constant INDEX_OF_ASSET = 2; // index of USDC in metapool
	uint256 internal constant DECIMAL_OFFSET = 1e12; // normalize USDC to 18 decimals

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized
	) Strategy(_vault, _treasury, _authorized) {
		_approve();
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		assets += asset.balanceOf(address(this));
		uint256 rewardBalance = reward.balanceOf(address(this));
		if (rewardBalance == 0) return assets;
		assets += zap.calc_withdraw_one_coin(address(pool), reward.balanceOf(address(this)), 2);
	}

	/*////////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized      /
	////////////////////////////////////////////////*/

	function reapprove() external onlyAuthorized {
		_unapprove();
		_approve();
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 assets = totalAssets();
		if (assets == 0) return 0;

		uint256 amount = _assets > assets ? assets : _assets;
		uint256 tokenAmount = (amount * reward.balanceOf(address(this))) / totalAssets();

		reward.withdraw(tokenAmount);
		received = zap.remove_liquidity_one_coin(address(pool), tokenAmount, INDEX_OF_ASSET, 0, _receiver);
	}

	function _harvest() internal override {
		reward.getReward();
		uint256 vaderBalance = VADER.balanceOf(address(this));
		if (vaderBalance == 0) return;

		minter.partnerMint(vaderBalance, 1);
		uint256 usdvBalance = USDV.balanceOf(address(this));

		if (fee > 0) {
			uint256 feeAmount = (usdvBalance * fee) / FEE_BASIS;
			USDV.safeTransfer(treasury, feeAmount);
			usdvBalance -= feeAmount;
		}

		uint256 received = pool.add_liquidity([usdvBalance, 0], 1);
		reward.stake(received);
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) return;

		uint256 received = zap.add_liquidity(address(pool), [0, 0, assetBalance, 0], 0);
		reward.stake(received);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit USDC into zap
		asset.safeApprove(address(zap), type(uint256).max);
		// approve deposit lpTokens into reward
		pool.safeApprove(address(reward), type(uint256).max);
		// approve withdraw lpTokens
		pool.safeApprove(address(zap), type(uint256).max);
		// approve deposit USDV into pool
		USDV.safeApprove(address(pool), type(uint256).max);
		// approve burn VADER for USDV
		VADER.safeApprove(address(USDV), type(uint256).max);
	}

	function _unapprove() internal {
		asset.safeApprove(address(zap), 0);
		pool.safeApprove(address(reward), 0);
		pool.safeApprove(address(zap), 0);
		USDV.safeApprove(address(pool), 0);
		VADER.safeApprove(address(USDV), 0);
	}
}
