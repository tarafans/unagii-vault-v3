// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "solmate/tokens/ERC20.sol";

contract MockWETH is ERC20("WETH", "WETH", 18) {
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}
