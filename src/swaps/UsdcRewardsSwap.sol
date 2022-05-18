// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import 'forge-std/console.sol'; // TODO: remove when done

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import '../interfaces/ISwap.sol';
import '../external/uniswap/ISwapRouter02.sol';

contract UsdcRewardsSwap is ISwap {
	using SafeTransferLib for ERC20;

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

	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	error UnsupportedToken(address);

	constructor() {
		routes[CRV] = Route.UniswapV2;
		routes[CVX] = Route.UniswapV3Path;
	}

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		Route route = routes[_tokenIn];
		if (route == Route.Unsupported) revert UnsupportedToken(_tokenIn);
		if (_tokenOut != USDC) revert UnsupportedToken(_tokenOut);

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);
		tokenIn.safeApprove(address(uniswap), _amount);

		// best for most amounts of CRV (though Uniswap V3 has better paths at really low/high routes)
		if (route == Route.UniswapV2) {
			address[] memory path = new address[](3);

			path[0] = _tokenIn;
			path[1] = WETH;
			path[2] = _tokenOut;

			return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
		}

		// best for certain trades, e.g. small amounts of CRV
		if (route == Route.UniswapV3Direct) {
			return
				uniswap.exactInputSingle(
					ISwapRouter02.ExactInputSingleParams({
						tokenIn: _tokenIn,
						tokenOut: _tokenOut,
						fee: 10_000, // 1% fee tier
						recipient: msg.sender,
						amountIn: _amount,
						amountOutMinimum: _minReceived,
						sqrtPriceLimitX96: 0
					})
				);
		}

		// best for CVX
		if (route == Route.UniswapV3Path) {
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

		revert UnsupportedToken(_tokenIn);
	}
}
