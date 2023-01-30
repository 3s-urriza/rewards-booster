// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract Token1 is ERC20, Ownable {
    constructor() ERC20("Token 1", "TK1") { }

    /**
     * @dev Mints a token amount.
     * @param to Address of the receiver.
     * @param amount Amount to be minted.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
