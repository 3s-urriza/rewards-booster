// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/Pool.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract PoolFactory is Ownable {
    event PoolCreated(
        address indexed asset, address depositFeeRecipient, uint32 baseRateTokensPerBlock, uint32 depositFee
    );

    constructor() { }

    /**
     * @dev Creates a new pool for the specified asset.
     * @param asset_ Asset for the new pool.
     * @param depositFeeRecipient_ depositFeeRecipient for the new pool.
     * @param baseRateTokensPerBlock_ baseRateTokensPerBlock for the new pool.
     * @param depositFee_ depositFee for the new pool.
     * @param rewardsMultiplierBlocks_ for the new pool.
     * @param rewardsMultipliers_ for the new pool.
     * @param withdrawFeeBlocks_ for the new pool.
     * @param withdrawFees_ Token for the new pool.
     */
    function createPool(
        address asset_,
        address depositFeeRecipient_,
        uint32 baseRateTokensPerBlock_,
        uint32 depositFee_,
        uint64[] memory rewardsMultiplierBlocks_,
        uint64[] memory rewardsMultipliers_,
        uint64[] memory withdrawFeeBlocks_,
        uint64[] memory withdrawFees_
    ) external onlyOwner returns (address newPool) {
        // Create the Pool.
        newPool = address(
            new Pool(asset_, depositFeeRecipient_, baseRateTokensPerBlock_, depositFee_, rewardsMultiplierBlocks_, rewardsMultipliers_, withdrawFeeBlocks_, withdrawFees_)
        );

        emit PoolCreated(asset_, depositFeeRecipient_, baseRateTokensPerBlock_, depositFee_);
    }
}
