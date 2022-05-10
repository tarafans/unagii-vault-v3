// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import 'solmate/utils/FixedPointMathLib.sol';

import './libraries/Ownership.sol';
import './interfaces/IERC4626.sol';
import './Strategy.sol';

contract Vault is ERC20, IERC4626, Ownership {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice token which the vault uses and accumulates
	ERC20 public immutable asset;
	// uint256 public immutable decimalOffset; // TODO: mechanism to normalize to 18

	uint256 _lockedProfit;
	/// @notice delay before locked profits are fully released
	uint256 public lockedProfitDuration = 6 hours;
	/// @notice timestamp of last report, used for locked profit calculations
	uint256 public lastReport;

	uint256 public constant MAX_LOCKED_PROFIT_DURATION = 3 days;

	struct StrategyParams {
		bool added;
		uint256 debt;
		uint256 debtRatio;
	}

	Strategy[] _queue;
	mapping(Strategy => StrategyParams) public strategies;

	uint256 internal constant MAX_QUEUE_LENGTH = 20;

	uint256 public totalDebt;
	uint256 public totalDebtRatio;
	uint256 public MAX_TOTAL_DEBT_RATIO = 3_600;

	/*///////////////
	/     Events    /
	///////////////*/

	event Report(Strategy indexed strategy, uint256 gain, uint256 loss);

	event StrategyAdded(Strategy indexed strategy, uint256 debtRatio);

	/*///////////////
	/     Errors    /
	///////////////*/

	error Zero();
	error BelowMinimum(uint256);
	error AboveMaximum(uint256);

	error AlreadyStrategy();
	error NotStrategy();
	error StrategyDoesNotBelongToQueue();
	error StrategyQueueFull();

	constructor(ERC20 _asset, address[] memory _authorized)
		ERC20(
			// e.g. USDC becomes 'Unagii USD Coin Vault v3' and 'uUSDCv3'
			string(abi.encodePacked('Unagii ', _asset.name(), ' Vault v3')),
			string(abi.encodePacked('u', _asset.symbol(), 'v3')),
			18
		)
		Ownership(_authorized)
	{
		asset = _asset;
	}

	/*///////////////////////
	/      Public View      /
  ///////////////////////*/

	function queue() external view returns (Strategy[] memory) {
		return _queue;
	}

	function totalInStrategies() public view returns (uint256 assets) {
		assets += asset.balanceOf(address(this));
		for (uint8 i = 0; i < _queue.length; ++i) {
			assets += _queue[i].totalAssets();
		}
	}

	function totalAssets() public view returns (uint256 assets) {
		return asset.balanceOf(address(this)) + totalInStrategies();
	}

	function lockedProfit() public view returns (uint256 lockedAssets) {
		unchecked {
			if (block.timestamp - lastReport > lockedProfitDuration) return 0;
			return ((_lockedProfit * (block.timestamp - lastReport)) / lockedProfitDuration);
		}
	}

	function freeAssets() public view returns (uint256 assets) {
		return totalAssets() - lockedProfit();
	}

	function convertToShares(uint256 _assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;
		return supply == 0 ? _assets : _assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 _shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), supply);
	}

	function maxDeposit(address) external pure returns (uint256 assets) {
		return type(uint256).max;
	}

	function previewDeposit(uint256 _assets) public view returns (uint256 shares) {
		return convertToShares(_assets);
	}

	function maxMint(address) external view returns (uint256 shares) {
		return type(uint256).max - totalSupply;
	}

	function previewMint(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
	}

	function maxWithdraw(address owner) external view returns (uint256 assets) {
		return convertToAssets(balanceOf[owner]);
	}

	function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;
		return supply == 0 ? assets : assets.mulDivUp(supply, freeAssets());
	}

	function maxRedeem(address _owner) external view returns (uint256 shares) {
		return balanceOf[_owner];
	}

	function previewRedeem(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivDown(freeAssets(), supply);
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function safeDeposit(
		uint256 _assets,
		address _receiver,
		uint256 _minShares
	) external returns (uint256 shares) {
		shares = deposit(_assets, _receiver);
		if (shares < _minShares) revert BelowMinimum(shares);
	}

	function safeMint(
		uint256 _shares,
		address _receiver,
		uint256 _maxAssets
	) external returns (uint256 assets) {
		assets = mint(_shares, _receiver);
		if (assets > _maxAssets) revert AboveMaximum(assets);
	}

	function safeWithdraw(
		uint256 _assets,
		address _receiver,
		address _owner,
		uint256 _maxShares
	) external returns (uint256 shares) {
		shares = withdraw(_assets, _receiver, _owner);
		if (shares > _maxShares) revert AboveMaximum(shares);
	}

	function safeRedeem(
		uint256 _shares,
		address _receiver,
		address _owner,
		uint256 _minAssets
	) external returns (uint256 assets) {
		assets = redeem(_shares, _receiver, _owner);
		if (assets < _minAssets) revert BelowMinimum(assets);
	}

	/*////////////////////////////////////
	/      ERC4626 Public Functions      /
	////////////////////////////////////*/

	function deposit(uint256 _assets, address _receiver) public returns (uint256 shares) {
		if ((shares = previewDeposit(_assets)) == 0) revert Zero();

		_deposit(_assets, shares, _receiver);
	}

	function mint(uint256 _shares, address _receiver) public returns (uint256 assets) {
		if (_shares == 0) revert Zero();
		assets = previewMint(_shares);

		_deposit(assets, _shares, _receiver);
	}

	function withdraw(
		uint256 _assets,
		address _receiver,
		address _owner
	) public returns (uint256 shares) {
		if (_assets == 0) revert Zero();
		shares = previewWithdraw(_assets);

		_withdraw(_assets, shares, _owner, _receiver);
	}

	function redeem(
		uint256 _shares,
		address _receiver,
		address _owner
	) public returns (uint256 assets) {
		if ((assets = previewRedeem(_shares)) == 0) revert Zero();

		_withdraw(assets, _shares, _owner, _receiver);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function addStrategy(Strategy _strategy, uint256 _debtRatio) external onlyOwner {
		if (_strategy.vault() != this) revert StrategyDoesNotBelongToQueue();
		if (strategies[_strategy].added) revert AlreadyStrategy();
		if (_queue.length >= MAX_QUEUE_LENGTH) revert StrategyQueueFull();

		totalDebtRatio += _debtRatio;
		if (totalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(totalDebtRatio);

		strategies[_strategy] = StrategyParams({added: true, debt: 0, debtRatio: _debtRatio});
		_queue.push(_strategy);

		emit StrategyAdded(_strategy, _debtRatio);
	}

	/*////////////////////////////////////////////
	/      Restricted Functions: onlyAdmins      /
	////////////////////////////////////////////*/

	function removeStrategy(Strategy _strategy) external onlyAdmins {}

	function setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) external onlyAdmins {}

	function setQueue(Strategy[] calldata _newQueue) external onlyAdmins {}

	function setLockedProfitDuration(uint256 _newDuration) external onlyAdmins {}

	/*///////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized      /
	///////////////////////////////////////////////*/

	function suspendStrategy(Strategy _strategy) external onlyAuthorized {}

	function pause() external onlyAuthorized {}

	function unpause() external onlyAuthorized {}

	function harvest() external onlyAuthorized {
		for (uint8 i = 0; i < _queue.length; ++i) {
			Strategy strategy = _queue[i];

			strategy.harvest();

			uint256 assets = strategy.totalAssets();
			uint256 debt = strategies[strategy].debt;

			uint256 gain;
			uint256 loss;

			if (assets > debt) {
				gain = assets - debt;
				_lockedProfit = lockedProfit() + gain;
			} else if (debt > assets) {
				loss = debt - assets;
				strategies[strategy].debt -= loss;
				totalDebt -= loss;

				uint256 lockedProfitBeforeLoss = lockedProfit();
				_lockedProfit = lockedProfitBeforeLoss > loss ? lockedProfitBeforeLoss - loss : 0;
			}

			emit Report(strategy, gain, loss);

			uint256 currentDebt = debt + gain;
			uint256 possibleDebt = totalDebtRatio == 0
				? 0
				: ((totalAssets() + gain) * strategies[strategy].debtRatio) / totalDebtRatio;

			if (currentDebt > possibleDebt) _lend(strategy, possibleDebt - currentDebt);
			if (possibleDebt > currentDebt) _collect(strategy, currentDebt - possibleDebt, address(this));
		}

		lastReport = block.timestamp;
	}

	/*////////////////////////////////////////////////
	/      Restricted Functions: onlyStrategies      /
	////////////////////////////////////////////////*/

	function report() external onlyStrategy {
		Strategy strategy = Strategy(msg.sender);

		uint256 assets = strategy.totalAssets();
		uint256 debt = strategies[strategy].debt;

		uint256 gain;

		if (assets > debt) {
			gain = assets - debt;
			_lockedProfit = lockedProfit() + gain;
		} else if (debt > assets) {
			uint256 loss = debt - assets;
			strategies[strategy].debt -= loss;
			totalDebt -= loss;

			uint256 lockedProfitBeforeLoss = lockedProfit();
			_lockedProfit = lockedProfitBeforeLoss > loss ? lockedProfitBeforeLoss - loss : 0;
		}

		uint256 currentDebt = debt + gain;
		uint256 possibleDebt = totalDebtRatio == 0
			? 0
			: ((totalAssets() + gain) * strategies[strategy].debtRatio) / totalDebtRatio;

		if (currentDebt > possibleDebt) _lend(strategy, possibleDebt - currentDebt);
		if (possibleDebt > currentDebt) _collect(strategy, currentDebt - possibleDebt, address(this));

		lastReport = block.timestamp;
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	// /// @dev an address cannot mint, burn send or receive share tokens on same block
	// function _mint(address _to, uint256 _amount) internal override useBlockDelay(_to) {
	// 	ERC20._mint(_to, _amount);
	// }

	// /// @dev an address cannot mint, burn send or receive share tokens on same block
	// function _burn(address _from, uint256 _amount) internal override useBlockDelay(_from) {
	// 	ERC20._burn(_from, _amount);
	// }

	// /// @dev an address cannot mint, burn send or receive share tokens on same block
	// function transfer(address _to, uint256 _amount)
	// 	public
	// 	override
	// 	useBlockDelay(msg.sender)
	// 	useBlockDelay(_to)
	// 	returns (bool)
	// {
	// 	return ERC20.transfer(_to, _amount);
	// }

	// /// @dev an address cannot mint, burn send or receive share tokens on same block
	// function transferFrom(
	// 	address _from,
	// 	address _to,
	// 	uint256 _amount
	// ) public override useBlockDelay(_from) useBlockDelay(_to) returns (bool) {
	// 	return ERC20.transferFrom(_from, _to, _amount);
	// }

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _deposit(
		uint256 _assets,
		uint256 _shares,
		address _receiver
	) internal {
		asset.safeTransferFrom(msg.sender, address(this), _assets);
		_mint(_receiver, _shares);
		emit Deposit(msg.sender, _receiver, _assets, _shares);
	}

	function _withdraw(
		uint256 _assets,
		uint256 _shares,
		address _owner,
		address _receiver
	) internal {
		if (msg.sender != _owner) {
			uint256 allowed = allowance[_owner][msg.sender];
			if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - _shares;
		}

		_burn(_owner, _shares);
		emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

		// first, withdraw from balance
		uint256 balance = asset.balanceOf(address(this));

		if (balance > 0) {
			uint256 amount = _assets > balance ? balance : _assets;
			asset.safeTransfer(_receiver, amount);
			_assets -= amount;
		}

		// next, withdraw from strategies
		for (uint8 i = 0; i < _queue.length; ++i) {
			if (_assets == 0) break;
			uint256 received = _collect(_queue[i], _assets, _receiver); // overflow is handled by strategy
			_assets -= received;
		}
	}

	function _lend(Strategy _strategy, uint256 _assets) internal {
		uint256 balance = asset.balanceOf(address(this));
		uint256 amount = _assets > balance ? balance : _assets;

		asset.safeTransfer(address(_strategy), amount);
		_strategy.invest();

		strategies[_strategy].debt += amount;
		totalDebt += amount;
	}

	function _collect(
		Strategy _strategy,
		uint256 _assets,
		address _receiver
	) internal returns (uint256 received) {
		received = _strategy.withdraw(_assets, _receiver);

		uint256 debt = strategies[_strategy].debt;

		uint256 amount = debt > received ? received : debt;

		strategies[_strategy].debt -= amount;
		totalDebt -= amount;
	}

	function _report(Strategy _strategy) internal {}

	/*/////////////////////
	/      Modifiers      /
  /////////////////////*/

	modifier onlyStrategy() {
		if (!strategies[Strategy(msg.sender)].added) revert NotStrategy();
		_;
	}
}
