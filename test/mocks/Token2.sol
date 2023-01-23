// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract Token2 is ERC20 {
    constructor() ERC20("Token 2", "TK2") { }

    /**
     * @dev Mints a token amount.
     * @param to Address of the receiver.
     * @param amount Amount to be minted.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
