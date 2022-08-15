// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import '../external/compound/IComptroller.sol';
import '../external/compound/ICerc20.sol';
import '../Swap.sol';
import '../Strategy.sol';

abstract contract StrategyCompound is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice contract used to swap COMP rewards to asset
	Swap public swap;

	/// @notice collateral ratio buffer
	/// @dev 1e18 = don't leverage
	uint256 public buffer = 0.04 * 1e18;

	IComptroller private constant comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
	ERC20 private constant COMP = ERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
	ICerc20 private immutable cToken;

	error CompoundErrorCode(uint256 errorCode);
	error NothingToInvest();
	error SomethingWentWrong();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		Swap _swap,
		address _cToken
	) Strategy(_vault, _treasury, _authorized) {
		swap = _swap;
		cToken = ICerc20(_cToken);
		if (cToken.underlying() != address(asset)) revert InvalidValue();

		_approve();
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function totalAssets() public view override returns (uint256) {
		(uint256 errorCode, uint256 balance, uint256 borrowed, uint256 exchangeRate) = cToken.getAccountSnapshot(
			address(this)
		);

		if (errorCode > 0) revert CompoundErrorCode(errorCode);

		uint256 supplied = balance.mulDivDown(exchangeRate, 1e18);

		if (supplied < borrowed) revert SomethingWentWrong();

		unchecked {
			return supplied - borrowed;
		}
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	/// @notice not a view function (as underlying compound functions are not view functions). call this on fork to save gas
	function getHealth()
		external
		returns (
			uint256 supplied,
			uint256 borrowed,
			uint256 marketCol,
			uint256 safeCol,
			uint256 collateralRatio
		)
	{
		supplied = cToken.balanceOfUnderlying(address(this));
		borrowed = cToken.borrowBalanceCurrent(address(this));

		(, marketCol, ) = comptroller.markets(address(cToken));
		safeCol = _getSafeCollateralRatio(marketCol);

		collateralRatio = supplied == 0 ? 0 : borrowed.mulDivUp(1e18, supplied);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function changeSwap(Swap _swap) external onlyOwner {
		_unapproveSwap();
		swap = _swap;
		_approveSwap();
	}

	/*////////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized      /
	////////////////////////////////////////////////*/

	function setBuffer(uint256 _buffer) external onlyAuthorized {
		if (_buffer == 0 || buffer > 1e18) revert InvalidValue();
		if (_buffer == buffer) revert AlreadyValue();
		buffer = _buffer;
		_rebalance();
	}

	function rebalance() external onlyAuthorized {
		_rebalance();
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 supplied = cToken.balanceOfUnderlying(address(this));
		uint256 borrowed = cToken.borrowBalanceCurrent(address(this));

		uint256 assets = supplied - borrowed; // also pre-withdrawal unleveraged

		if (assets == 0) return 0; // nothing to withdraw

		uint256 amount = _assets > assets ? assets : _assets;

		(, uint256 marketCol, ) = comptroller.markets(address(cToken));
		uint256 safeCol = _getSafeCollateralRatio(marketCol);

		uint256 unleveraged = assets - amount; // post-withdrawal unleveraged

		uint256 targetSupply = _getTargetSupply(unleveraged, safeCol);
		uint256 targetBorrowed = targetSupply - unleveraged;

		_deleverage(supplied, borrowed, targetSupply, targetBorrowed, marketCol);
		asset.safeTransfer(_receiver, amount);
	}

	function _harvest() internal override {
		address[] memory cTokens = new address[](1);
		cTokens[0] = address(cToken);
		comptroller.claimComp(address(this), cTokens);

		uint256 compBal = COMP.balanceOf(address(this));
		if (compBal == 0) revert SomethingWentWrong();

		if (fee > 0) {
			uint256 feeAmount = _calculateFee(compBal);
			COMP.safeTransfer(treasury, feeAmount);
			compBal -= feeAmount;
		}

		swap.swapTokens(address(COMP), address(asset), compBal, 1);
		asset.safeTransfer(address(vault), asset.balanceOf(address(this)));
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();
		_mint(assetBalance);
		_rebalance();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _rebalance() internal {
		uint256 supplied = cToken.balanceOfUnderlying(address(this));
		uint256 borrowed = cToken.borrowBalanceCurrent(address(this));

		uint256 unleveraged = supplied - borrowed;

		(, uint256 marketCol, ) = comptroller.markets(address(cToken));
		uint256 safeCol = _getSafeCollateralRatio(marketCol);

		uint256 targetSupply = _getTargetSupply(unleveraged, safeCol);
		uint256 targetBorrowed = targetSupply - unleveraged;

		if (supplied < targetSupply) _leverage(supplied, borrowed, targetSupply, marketCol);
		else if (supplied > targetSupply) _deleverage(supplied, borrowed, targetSupply, targetBorrowed, marketCol);
	}

	function _leverage(
		uint256 _supplied,
		uint256 _borrowed,
		uint256 _targetSupply,
		uint256 _marketCollateralRatio
	) internal {
		uint8 iterations;

		while (_supplied < _targetSupply) {
			uint256 borrowAmount = _getBorrowAmount(_supplied, _borrowed, _marketCollateralRatio);

			uint256 diff = _targetSupply - _supplied;
			if (borrowAmount > diff) borrowAmount = diff;

			_borrow(borrowAmount);
			_mint(borrowAmount);
			_supplied += borrowAmount;
			_borrowed += borrowAmount;

			++iterations;
			if (iterations > 25) revert SomethingWentWrong();
		}
	}

	function _deleverage(
		uint256 _supplied,
		uint256 _borrowed,
		uint256 _targetSupply,
		uint256 _targetBorrowed,
		uint256 _marketCollateralRatio
	) internal {
		uint8 iterations;

		while (_supplied > _targetSupply || _borrowed > _targetBorrowed) {
			uint256 redeemAmount = _getRedeemAmount(_supplied, _borrowed, _marketCollateralRatio);
			uint256 diff = _supplied - _targetSupply;
			if (redeemAmount > diff) redeemAmount = diff;

			uint256 diffBorrowed = _borrowed - _targetBorrowed;
			uint256 repayAmount = diffBorrowed < redeemAmount ? diffBorrowed : redeemAmount;

			_redeem(redeemAmount);
			_repay(repayAmount);
			_supplied -= redeemAmount;
			_borrowed -= repayAmount;

			++iterations;
			if (iterations > 25) revert SomethingWentWrong();
		}
	}

	function _getSafeCollateralRatio(uint256 _marketCollateralRatio)
		internal
		view
		returns (uint256 safeCollateralRatio)
	{
		return _marketCollateralRatio > buffer ? _marketCollateralRatio - buffer : 0;
	}

	function _getTargetSupply(uint256 _unleveraged, uint256 _safeCollateralRatio)
		internal
		pure
		returns (uint256 targetSupply)
	{
		// if _safeCollateralRatio = 0, targetSupply = unleveraged (aka borrowed = 0)
		if (_safeCollateralRatio == 0) return _unleveraged;
		// 1 / (1 - c)
		return _unleveraged.mulDivDown(1e18, 1e18 - _safeCollateralRatio);
	}

	/// @dev maximum amount that can be borrowed without going below _marketCol
	function _getBorrowAmount(
		uint256 _supplied,
		uint256 _borrowed,
		uint256 _marketCol
	) internal pure returns (uint256) {
		uint256 max = _supplied.mulDivDown(_marketCol, 1e18);
		if (_borrowed >= max) return 0;
		return max - _borrowed;
	}

	/// @dev maximum amount that can be redeemed without going below _marketCol
	function _getRedeemAmount(
		uint256 _supplied,
		uint256 _borrowed,
		uint256 _marketCol
	) internal pure returns (uint256) {
		uint256 min = _borrowed.mulDivUp(1e18, _marketCol);
		if (_supplied <= min) return 0;
		return _supplied - min;
	}

	/// @dev asset -> cToken
	function _mint(uint256 _assetAmount) internal {
		uint256 errorCode = cToken.mint(_assetAmount);
		if (errorCode > 0) revert CompoundErrorCode(errorCode);
	}

	/// @dev cToken -> asset
	function _redeem(uint256 _assetAmount) internal {
		uint256 errorCode = cToken.redeemUnderlying(_assetAmount);
		if (errorCode > 0) revert CompoundErrorCode(errorCode);
	}

	function _borrow(uint256 _assetAmount) internal {
		uint256 errorCode = cToken.borrow(_assetAmount);
		if (errorCode > 0) revert CompoundErrorCode(errorCode);
	}

	function _repay(uint256 _assetAmount) internal {
		uint256 errorCode = cToken.repayBorrow(_assetAmount);
		if (errorCode > 0) revert CompoundErrorCode(errorCode);
	}

	function _approve() internal {
		// approve mint asset into cToken
		asset.safeApprove(address(cToken), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		asset.safeApprove(address(cToken), 0);

		_unapproveSwap();
	}

	function _unapproveSwap() internal {
		COMP.safeApprove(address(swap), 0);
	}

	// approve swap COMP to asset
	function _approveSwap() internal {
		COMP.safeApprove(address(swap), type(uint256).max);
	}
}
