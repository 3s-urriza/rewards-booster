// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract DepositContract is Ownable {
    ///@notice Mapping to store the whitelisted tokens.
    mapping(address => bool) private whitelistedTokens;

    ///@notice Array to store the Pools.
    address[] private pools;

    constructor() { }

    /**
     * @dev Adds a whitelisted token.
     * @param token Token address to be whitelisted.
     */
    function addWhitelistedToken(address token) external onlyOwner {
        // Add the token to the whitelistedTokens mapping.
        whitelistedTokens[token] = true;
    }

    /**
     * @dev Removes a whitelisted token.
     * @param token Token address to be removed from being whitelisted.
     */
    function removeWhitelistedToken(address token) external onlyOwner {
        // Remove the token to the whitelistedTokens mapping.
        whitelistedTokens[token] = false;
    }

    /**
     * @dev Claims rewards for the specified pools.
     * @param _pools Pools to claim the reward.
     */
    function claimRewards(address[] memory _pools) external {
        /*
            1. Call claimRewards on every Pool.
        */
    }
}
