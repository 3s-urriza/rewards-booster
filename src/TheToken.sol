// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/interfaces/ITheToken.sol";

import "@openzeppelin/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract TheToken is ERC20, ITheToken, Ownable {
    constructor() ERC20("TheToken", "TTK") { }

    /**
     * @dev Mints a token amount.
     * @param to Address of the receiver.
     * @param amount Amount to be minted.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
