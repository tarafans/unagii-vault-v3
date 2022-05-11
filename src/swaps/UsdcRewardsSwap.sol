// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import 'forge-std/console.sol'; // TODO: remove when done

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import '../interfaces/ISwap.sol';
import '../external/uniswap/ISwapRouter02.sol';
import '../external/sushiswap/ISushiRouter.sol';

contract UsdcRewardsSwap is ISwap {
	using SafeTransferLib for ERC20;

	enum Route {
		Unsupported,
		UniswapV3Direct
	}
	// TODO:
	// UniswapV2,
	// UniswapV3, CRV/CVX -> WETH -> USDC
	// SushiSwap

	ISwapRouter02 public uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
	// ISushiRouter public sushiswap = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

	mapping(address => Route) public routes;

	address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
	address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	error UnsupportedToken(address);

	constructor() {
		// for CRV & CVX with the amounts we swap, uniswap v3 1% rate pool has the best rates
		routes[CRV] = Route.UniswapV3Direct;
		routes[CVX] = Route.UniswapV3Direct;
	}

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		Route route = routes[_tokenIn]; // defaults to UniswapV2

		if (route == Route.Unsupported) revert UnsupportedToken(_tokenIn);

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);
		tokenIn.safeApprove(address(uniswap), _amount);

		ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: 10_000, // 1% fee tier
			recipient: msg.sender,
			amountIn: _amount,
			amountOutMinimum: _minReceived,
			sqrtPriceLimitX96: 0
		});

		received = uniswap.exactInputSingle(params);

		// }

		// if (route == Route.UniswapV3) {
		// 	tokenIn.safeApprove(address(uniswap), _amount);
		// }

		// // else, is v2 swap

		// address[] memory path = new address[](3);
		// path[0] = _tokenIn;
		// path[1] = WETH;
		// path[2] = _tokenOut;

		// if (route == Route.UniswapV2) {
		// 	tokenIn.safeApprove(address(uniswap), _amount);

		// 	return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
		// }

		// if (route == Route.SushiSwap) {
		// 	tokenIn.safeApprove(address(sushiswap), _amount);

		// 	uint256[] memory amountsReceived = sushiswap.swapExactTokensForTokens(
		// 		_amount,
		// 		_minReceived,
		// 		path,
		// 		msg.sender,
		// 		block.timestamp + 30 minutes
		// 	);

		// 	return amountsReceived[amountsReceived.length - 1];
		// }
	}

	// function addRoute(address _token, Route _route) external {}
}
