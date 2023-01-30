// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "test/mocks/Token1.sol";
import "src/PoolFactory.sol";
import "src/Pool.sol";
import "src/BoosterPack.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract PoolFactoryTest is Test {
    PoolFactory public poolFactory;
    Pool public pool;
    BoosterPack public boosterPack;
    Token1 public token1;

    address public deployer = vm.addr(1500);
    address public user1 = vm.addr(1501);

    function setUp() public {
        // Label addresses
        vm.label(deployer, "Deployer");
        vm.label(user1, "User 1");

        vm.startPrank(deployer);

        token1 = new Token1();
        boosterPack = new BoosterPack("");
        poolFactory = new PoolFactory();

        vm.stopPrank();
    }

    function test_createPool() public {
        // Set the initial data
        address asset_ = address(token1);
        address depositFeeRecipient_ = deployer;
        uint32 baseRateTokensPerBlock_ = 20;
        uint32 depositFee_ = 10;

        // RewardsMultiplier
        uint64[] memory rewardsMultiplierBlocks_;
        uint64[] memory rewardsMultipliers_;

        // WithdrawFees
        uint64[] memory withdrawFeeBlocks_;
        uint64[] memory withdrawFees_;

        // Unhappy path Nº1 - Trying to create a Pool without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );

        vm.stopPrank();

        vm.startPrank(deployer);
        // Unhappy path Nº2 - Trying to create a Pool without passing reward multipliers.
        vm.expectRevert(abi.encodeWithSignature("Pool_RewardMultipliersAmountZeroError()"));
        poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );
        rewardsMultiplierBlocks_ = new uint64[](4);
        rewardsMultiplierBlocks_[0] = 100;
        rewardsMultiplierBlocks_[1] = 200;
        rewardsMultiplierBlocks_[2] = 300;
        rewardsMultiplierBlocks_[3] = 400;
        rewardsMultipliers_ = new uint64[](3);

        // Unhappy path Nº3 - Trying to create a Pool without passing the same number of reward multipliers parameters.
        vm.expectRevert(abi.encodeWithSignature("Pool_InitializeRewardMultipliersParametersFormatError()"));
        poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );
        rewardsMultipliers_ = new uint64[](4);
        rewardsMultipliers_[0] = 100;
        rewardsMultipliers_[1] = 50;
        rewardsMultipliers_[2] = 25;
        rewardsMultipliers_[3] = 10;

        // Unhappy path Nº4 - Trying to create a Pool without passing withdraw fees.
        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeesAmountZeroError()"));
        poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );
        withdrawFeeBlocks_ = new uint64[](4);
        withdrawFeeBlocks_[0] = 0;
        withdrawFeeBlocks_[1] = 100;
        withdrawFeeBlocks_[2] = 1000;
        withdrawFeeBlocks_[3] = 10_000;
        withdrawFees_ = new uint64[](3);

        // Unhappy path Nº5 - Trying to create a Pool without passing the same number of withdraw fees parameters.
        vm.expectRevert(abi.encodeWithSignature("Pool_InitializeWithdrawFeesParametersFormatError()"));
        poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );
        withdrawFees_ = new uint64[](4);
        withdrawFees_[0] = 15;
        withdrawFees_[1] = 10;
        withdrawFees_[2] = 5;
        withdrawFees_[3] = 2;

        // Happy path - Being the Owner and passing the correct parameters.
        address poolAddress = poolFactory.createPool(
            asset_,
            depositFeeRecipient_,
            baseRateTokensPerBlock_,
            depositFee_,
            rewardsMultiplierBlocks_,
            rewardsMultipliers_,
            withdrawFeeBlocks_,
            withdrawFees_,
            address(boosterPack)
        );
        pool = Pool(poolAddress);

        vm.stopPrank();

        vm.startPrank(address(poolFactory));

        assertEq(pool.getBaseRateTokensPerBlock(), 20);
        assertEq(pool.getDepositFee(), 10);
        assertEq(pool.getRewardsMultiplierBlockNumber(0), 100);
        assertEq(pool.getRewardsMultiplier(0), 100);
        assertEq(pool.getRewardsMultiplierBlockNumber(1), 200);
        assertEq(pool.getRewardsMultiplier(1), 50);
        assertEq(pool.getRewardsMultiplierBlockNumber(2), 300);
        assertEq(pool.getRewardsMultiplier(2), 25);
        assertEq(pool.getRewardsMultiplierBlockNumber(3), 400);
        assertEq(pool.getRewardsMultiplier(3), 10);
        assertEq(pool.getWithdrawFeeBlockNumber(0), 0);
        assertEq(pool.getWithdrawFee(0), 15);
        assertEq(pool.getWithdrawFeeBlockNumber(1), 100);
        assertEq(pool.getWithdrawFee(1), 10);
        assertEq(pool.getWithdrawFeeBlockNumber(2), 1000);
        assertEq(pool.getWithdrawFee(2), 5);
        assertEq(pool.getWithdrawFeeBlockNumber(3), 10_000);
        assertEq(pool.getWithdrawFee(3), 2);

        vm.stopPrank();
    }
}
