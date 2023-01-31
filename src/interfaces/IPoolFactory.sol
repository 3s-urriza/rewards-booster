// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPoolFactory {
    function createPool(
        address,
        address,
        uint32,
        uint32,
        uint64[] memory,
        uint64[] memory,
        uint64[] memory,
        uint64[] memory,
        address
    ) external returns (address);
}
