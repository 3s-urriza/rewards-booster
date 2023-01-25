// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBoosterPack {

    function addWhitelistedAddrBP(address) external;

    function removeWhitelistedAddrBP(address) external;

    function mintBP(address, uint256, uint64, uint64, uint32) external;

    function burnBP(uint256) external;
}