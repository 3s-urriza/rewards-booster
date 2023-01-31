// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPoolManager {
    function addWhitelistedToken(address) external;

    function removeWhitelistedToken(address) external;

    function createPool(
        address,
        address,
        uint32,
        uint32,
        uint64[] memory,
        uint64[] memory,
        uint64[] memory,
        uint64[] memory
    ) external;

    function claimRewards(address[] memory) external;
}
