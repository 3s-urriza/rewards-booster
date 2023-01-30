// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/token/ERC1155/IERC1155.sol";

interface IBoosterPack is IERC1155 {
    function addWhitelistedAddrBP(address) external;

    function removeWhitelistedAddrBP(address) external;

    function setAttributes(uint256, uint64, uint64, uint32) external;

    function mint(address, uint256, uint256, uint64, uint64, uint32) external;

    function burn(uint256, uint256) external;

    function getWhitelistedAddrBP(address) external returns (bool);

    function getDuration(uint32) external returns (uint64);

    function getExpirationDate(uint32) external returns (uint64);

    function getMultiplier(uint32) external returns (uint32);
}
