// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import '../interfaces/ISwap.sol';
import '../libraries/Ownable.sol';
import '../external/uniswap/ISwapRouter02.sol';

/**
 * @notice
 * Swap contract used by USDC vault to:
 * 1. swap rewards to USDC
 * 2. zap other stablecoin (USDT & DAI) into USDC
 */
contract WbtcSwap is ISwap, Ownable {
	using SafeTransferLib for ERC20;

	// TODO: also support Curve and SushiSwap?
	enum Route {
		Unsupported,
		UniswapV2,
		UniswapV3Direct,
		UniswapV3Path
	}

	/// @dev single address which supports both uniswap v2 and v3 routes
	ISwapRouter02 internal constant uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	mapping(address => Route) public routes;

	address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
	address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error UnsupportedToken(address);

	constructor() Ownable() {
		routes[CRV] = Route.UniswapV2; // TODO: sushiswap is better
		routes[CVX] = Route.UniswapV3Path;
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		Route route = routes[_tokenIn];
		if (route == Route.Unsupported) revert UnsupportedToken(_tokenIn);
		if (_tokenOut != WBTC) revert UnsupportedToken(_tokenOut);

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);
		tokenIn.safeApprove(address(uniswap), _amount);

		if (route == Route.UniswapV2) return _uniswapV2(_tokenIn, _tokenOut, _amount, _minReceived);
		if (route == Route.UniswapV3Direct) return _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived);
		if (route == Route.UniswapV3Path) return _uniswapV3Path(_tokenIn, _tokenOut, _amount, _minReceived);

		revert UnsupportedToken(_tokenIn);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setToken(address _token, Route _route) external onlyOwner {
		routes[_token] = _route;
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _uniswapV2(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) internal returns (uint256) {
		address[] memory path = new address[](3);

		path[0] = _tokenIn;
		path[1] = WETH;
		path[2] = _tokenOut;

		return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
	}

	function _uniswapV3Direct(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) internal returns (uint256) {
		return
			uniswap.exactInputSingle(
				ISwapRouter02.ExactInputSingleParams({
					tokenIn: _tokenIn,
					tokenOut: _tokenOut,
					fee: 100,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived,
					sqrtPriceLimitX96: 0
				})
			);
	}

	function _uniswapV3Path(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) internal returns (uint256) {
		return
			uniswap.exactInput(
				ISwapRouter02.ExactInputParams({
					path: abi.encodePacked(_tokenIn, uint24(10_000), WETH, uint24(500), _tokenOut),
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived
				})
			);
	}
}
