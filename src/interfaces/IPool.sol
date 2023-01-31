// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPool {
    // Pool Parameters
    function updateBaseRateTokensPerBlock(uint32) external;

    function updateDepositFee(uint32) external;

    function addRewardsMultiplier(uint32, uint32) external;

    function updateRewardsMultiplier(uint32, uint32, uint32) external;

    function removeRewardsMultiplier(uint32) external;

    function addWithdrawFee(uint32, uint32) external;

    function updateWithdrawFee(uint32, uint32, uint32) external;

    function removeWithdrawFee(uint32) external;

    // Pool Actions
    function deposit(uint128) external;

    function withdraw(uint128) external;

    function claimRewards(address) external;

    function burnBP(uint32) external;

    function pause() external;

    function unpause() external;
}
