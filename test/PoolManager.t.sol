// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "test/mocks/Token1.sol";
import "test/mocks/Token2.sol";
import "src/PoolManager.sol";
import "src/BoosterPack.sol";
import "src/interfaces/IPool.sol";
import "src/Pool.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract PoolManagerTest is Test {
    PoolManager public poolManager;
    Token1 public token1;
    Token2 public token2;
    BoosterPack public boosterPack;

    address public deployer = vm.addr(1500);
    address public user1 = vm.addr(1501);
    address public user2 = vm.addr(1502);

    // Pool parameters
    address depositFeeRecipient;
    uint32 baseRateTokensPerBlock;
    uint32 depositFee;

    // RewardsMultiplier
    uint64[] rewardsMultiplierBlocks = new uint64[](4);
    uint64[] rewardsMultipliers = new uint64[](4);

    // WithdrawFees
    uint64[] withdrawFeeBlocks = new uint64[](4);
    uint64[] withdrawFees = new uint64[](4);

    function setUp() public {
        // Label addresses
        vm.label(deployer, "Deployer");
        vm.label(user1, "User 1");
        vm.label(user1, "User 2");

        vm.startPrank(deployer);

        token1 = new Token1();
        token2 = new Token2();
        poolManager = new PoolManager();
        boosterPack = poolManager.getBoosterPack();

        // Deal the accounts
        token1.mint(user1, 1000);
        token2.mint(user1, 1000);

        // Set the initial data
        depositFeeRecipient = deployer;
        baseRateTokensPerBlock = 20;
        depositFee = 10;

        // RewardsMultiplier
        rewardsMultiplierBlocks[0] = 100;
        rewardsMultiplierBlocks[1] = 200;
        rewardsMultiplierBlocks[2] = 300;
        rewardsMultiplierBlocks[3] = 400;
        rewardsMultipliers[0] = 100;
        rewardsMultipliers[1] = 50;
        rewardsMultipliers[2] = 25;
        rewardsMultipliers[3] = 10;

        // WithdrawFees
        withdrawFeeBlocks[0] = 0;
        withdrawFeeBlocks[1] = 100;
        withdrawFeeBlocks[2] = 1000;
        withdrawFeeBlocks[3] = 10_000;
        withdrawFees[0] = 15;
        withdrawFees[1] = 10;
        withdrawFees[2] = 5;
        withdrawFees[3] = 2;

        vm.stopPrank();
    }

    function test_constructor() public {
        poolManager = new PoolManager();
        boosterPack = poolManager.getBoosterPack();

        assertEq(poolManager.getPools().length, 0);
        assertEq(poolManager.getWhitelistedToken(address(token1)), false);
    }

    function test_addWhitelistedToken() public {
        // Unhappy path Nº1 - Trying to whitelist a token without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        poolManager.addWhitelistedToken(address(token1));

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        poolManager.addWhitelistedToken(address(token1));
        assertTrue(poolManager.getWhitelistedToken(address(token1)));

        vm.stopPrank();
    }

    function test_removeWhitelistedToken() public {
        // Set up
        vm.startPrank(deployer);

        poolManager.addWhitelistedToken(address(token1));

        vm.stopPrank();

        // Unhappy path Nº1 - Trying to whitelist a token without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        poolManager.removeWhitelistedToken(address(token1));

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        poolManager.removeWhitelistedToken(address(token1));
        assertFalse(poolManager.getWhitelistedToken(address(token1)));

        vm.stopPrank();
    }

    function test_createPool() public {
        // Unhappy path Nº1 - Trying to create a Pool without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        poolManager.createPool(
            address(token1),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );

        vm.stopPrank();

        vm.startPrank(deployer);
        // Unhappy path Nº2 - Trying to create a Pool with a token that is not whitelisted.
        vm.expectRevert(abi.encodeWithSignature("PoolManager_TokenNotWhitelisted()"));
        poolManager.createPool(
            address(token1),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        poolManager.addWhitelistedToken(address(token1));

        // Happy path - Being the Owner and the token is whitelisted.
        poolManager.createPool(
            address(token1),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        assertEq(poolManager.getPools().length, 1);
        address poolAddressToken1_ = poolManager.getPools()[0];
        assertTrue(Pool(poolManager.getPools()[0]).supportsInterface(type(IPool).interfaceId));

        vm.stopPrank();

        vm.startPrank(address(poolManager));

        assertTrue(boosterPack.getWhitelistedAddrBP(poolAddressToken1_));

        vm.stopPrank();
    }

    function test_createMultiplePools() public {
        vm.startPrank(deployer);

        poolManager.addWhitelistedToken(address(token1));
        poolManager.addWhitelistedToken(address(token2));

        // Happy path - Being the Owner and the token is whitelisted.
        poolManager.createPool(
            address(token1),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        poolManager.createPool(
            address(token2),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        address poolAddressToken1_ = poolManager.getPools()[0];
        address poolAddressToken2_ = poolManager.getPools()[1];

        assertTrue(Pool(poolManager.getPools()[0]).supportsInterface(type(IPool).interfaceId));
        assertTrue(Pool(poolManager.getPools()[1]).supportsInterface(type(IPool).interfaceId));

        vm.stopPrank();

        vm.startPrank(address(poolManager));

        assertTrue(boosterPack.getWhitelistedAddrBP(poolAddressToken1_));
        assertTrue(boosterPack.getWhitelistedAddrBP(poolAddressToken2_));

        vm.stopPrank();
    }

    function test_claimRewards() public {
        // Set up
        vm.startPrank(deployer);

        poolManager.addWhitelistedToken(address(token1));
        poolManager.addWhitelistedToken(address(token2));

        poolManager.createPool(
            address(token1),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        poolManager.createPool(
            address(token2),
            depositFeeRecipient,
            baseRateTokensPerBlock,
            depositFee,
            rewardsMultiplierBlocks,
            rewardsMultipliers,
            withdrawFeeBlocks,
            withdrawFees
        );
        address poolAddressToken1_ = poolManager.getPools()[0];
        address poolAddressToken2_ = poolManager.getPools()[1];

        vm.stopPrank();

        vm.startPrank(user1);

        token1.approve(poolAddressToken1_, 500);
        IPool(poolAddressToken1_).deposit(500);
        vm.roll(50);

        address[] memory pools_ = new address[](2);
        pools_[0] = poolAddressToken1_;
        pools_[1] = poolAddressToken2_;
        poolManager.claimRewards(pools_);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 98_499);
        assertEq(token1.balanceOf(address(poolAddressToken1_)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        /*assertEq(pool.getRewardsPerToken(), 217_777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 97_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);*/

        vm.stopPrank();
    }
}
