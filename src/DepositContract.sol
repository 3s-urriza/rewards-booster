// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract DepositContract is Ownable {
    ///@notice Mapping to store the whitelisted tokens.
    mapping(address => bool) private _whitelistedTokens;

    ///@notice Array to store the Pools.
    address[] private _pools;

    constructor() { }

    /**
     * @dev Adds a whitelisted token.
     * @param token_ Token address to be whitelisted.
     */
    function addWhitelistedToken(address token_) external onlyOwner {
        // Add the token to the _whitelistedTokens mapping.
        _whitelistedTokens[token_] = true;
    }

    /**
     * @dev Removes a whitelisted token.
     * @param token_ Token address to be removed from being whitelisted.
     */
    function removeWhitelistedToken(address token_) external onlyOwner {
        // Remove the token to the _whitelistedTokens mapping.
        _whitelistedTokens[token_] = false;
    }

    /**
     * @dev Claims rewards for the specified pools.
     * @param pools_ Pools to claim the reward.
     */
    function claimRewards(address[] memory pools_) external {
        // Call claimRewards on every Pool
        for (uint256 i = 0; i < pools_.length; i++) { }
    }
}
