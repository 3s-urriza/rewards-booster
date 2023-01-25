// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/interfaces/IPoolManager.sol";
import "src/interfaces/IPool.sol";
import "src/PoolFactory.sol";
import "src/BoosterPack.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";

/// Errors
error PoolManager_TokenNotWhitelisted();

contract PoolManager is IPoolManager, Ownable {
    ///@notice Mapping to store the whitelisted tokens.
    mapping(address => bool) private _whitelistedTokens;

    ///@notice Array to store the Pools.
    address[] private _pools;

    ///@notice PoolFactory
    PoolFactory private _poolFactory;

    ///@notice BoosterPack
    BoosterPack private _boosterPack;

    constructor() {
        _poolFactory = new PoolFactory();

        string memory _baseURI = "";
        _boosterPack = new BoosterPack(_baseURI);
    }

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
     * @dev Creates a new pool for the specified token.
     * @param token_ Token for the new pool.
     * @param depositFeeRecipient_ depositFeeRecipient for the new pool.
     * @param baseRateTokensPerBlock_ baseRateTokensPerBlock for the new pool.
     * @param depositFee_ depositFee for the new pool.
     * @param rewardsMultiplierBlocks_ for the new pool.
     * @param rewardsMultipliers_ for the new pool.
     * @param withdrawFeeBlocks_ for the new pool.
     * @param withdrawFees_ Token for the new pool.
     */
    function createPool(
        address token_,
        address depositFeeRecipient_,
        uint32 baseRateTokensPerBlock_,
        uint32 depositFee_,
        uint64[] memory rewardsMultiplierBlocks_,
        uint64[] memory rewardsMultipliers_,
        uint64[] memory withdrawFeeBlocks_,
        uint64[] memory withdrawFees_
    ) external onlyOwner {
        // Check if the token is whitelisted.
        if (!_whitelistedTokens[token_]) revert PoolManager_TokenNotWhitelisted();

        // Create the Pool.
        address newPool_ = _poolFactory.createPool(
            token_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_
        );

        // Add the Pool to the array of pools.
        _pools.push(newPool_);

        // Add the Pool address to the whitelisted addresses allowed to burn Booster Packs.
        _boosterPack.addWhitelistedAddrBP(newPool_);
    }

    /**
     * @dev Claims rewards for the specified pools.
     * @param pools_ Pools to claim the reward.
     */
    function claimRewards(address[] memory pools_) external {
        // Call claimRewards on every Pool
        for (uint256 i = 0; i < pools_.length; i++) {
            IPool(pools_[i]).claimRewards(msg.sender);
        }
    }

    // *** Getters ***

    /**
     * @dev Getter for the _whitelistedTokens mapping.
     * @param token_ Address of the token.
     */
    function getWhitelistedToken(address token_) external view onlyOwner returns (bool) {
        return _whitelistedTokens[token_];
    }

    /**
     * @dev Getter for the _pools array.
     */
    function getPools() external view onlyOwner returns (address[] memory) {
        return _pools;
    }

    /**
     * @dev Getter for the _boosterPack variable.
     */
    function getBoosterPack() external view onlyOwner returns (BoosterPack) {
        return _boosterPack;
    }
}
