// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract PoolFactory {
    constructor() { }

    /**
     * @dev Creates a new pool for the specified asset.
     * @param asset Asset for the new pool.
     * @param baseRateTokensPerBlock baseRateTokensPerBlock for the new pool.
     * @param depositFee depositFee for the new pool.
     * @param rewardsMultiplierBlocks for the new pool.
     * @param rewardsMultipliers for the new pool.
     * @param withdrawFeeBlocks for the new pool.
     * @param withdrawFees Token for the new pool.
     */
    function createPool(
        address asset,
        uint32 baseRateTokensPerBlock,
        uint32 depositFee,
        uint32[] memory rewardsMultiplierBlocks,
        uint32[] memory rewardsMultipliers,
        uint32[] memory withdrawFeeBlocks,
        uint64[] memory withdrawFees
    ) external {
        /*
            1. Creates the pool.
        */
    }
}
