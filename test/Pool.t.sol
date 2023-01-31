// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "test/mocks/Token1.sol";
import "test/mocks/Token2.sol";
import "src/Pool.sol";
import "src/BoosterPack.sol";
import "src/TheToken.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract PoolTest is
    Test // TO-DO Fixture
{
    Pool public pool;
    BoosterPack public boosterPack;
    Token1 public token1;
    Token2 public token2;

    address public deployer = vm.addr(1500);
    address public user1 = vm.addr(1501);
    address public user2 = vm.addr(1502);
    address public user3 = vm.addr(1503);
    address public user4 = vm.addr(1504);

    function setUp() public {
        // Label addresses
        vm.label(deployer, "Deployer");
        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        vm.label(user3, "User 3");
        vm.label(user4, "User 4");

        vm.startPrank(deployer);

        token1 = new Token1();
        token2 = new Token2();
        boosterPack = new BoosterPack("");

        // Set the initial data
        // RewardsMultiplier
        uint64[] memory rewardsMultiplierBlocks = new uint64[](4);
        rewardsMultiplierBlocks[0] = 100;
        rewardsMultiplierBlocks[1] = 200;
        rewardsMultiplierBlocks[2] = 300;
        rewardsMultiplierBlocks[3] = 400;
        uint64[] memory rewardsMultipliers = new uint64[](4);
        rewardsMultipliers[0] = 100;
        rewardsMultipliers[1] = 50;
        rewardsMultipliers[2] = 25;
        rewardsMultipliers[3] = 10;

        // WithdrawFees
        uint64[] memory withdrawFeeBlocks = new uint64[](4);
        withdrawFeeBlocks[0] = 0;
        withdrawFeeBlocks[1] = 100;
        withdrawFeeBlocks[2] = 1000;
        withdrawFeeBlocks[3] = 10_000;
        uint64[] memory withdrawFees = new uint64[](4);
        withdrawFees[0] = 15;
        withdrawFees[1] = 10;
        withdrawFees[2] = 5;
        withdrawFees[3] = 2;

        pool =
        new Pool(address(token1), deployer, 20, 10, rewardsMultiplierBlocks, rewardsMultipliers, withdrawFeeBlocks, withdrawFees, address(boosterPack));

        // Deal the accounts
        token1.mint(user1, 1000);
        token1.mint(user2, 1000);
        token1.mint(user3, 1000);
        token1.mint(user4, 1000);

        token2.mint(user1, 1000);
        token2.mint(user2, 1000);
        token2.mint(user3, 1000);
        token2.mint(user4, 1000);

        vm.stopPrank();
    }

    // TO-DO Separate from Pool Logic

    function test_constructor() public {
        // Set the initial data
        // RewardsMultiplier
        uint64[] memory rewardsMultiplierBlocks = new uint64[](4);
        rewardsMultiplierBlocks[0] = 100;
        rewardsMultiplierBlocks[1] = 200;
        rewardsMultiplierBlocks[2] = 300;
        rewardsMultiplierBlocks[3] = 400;
        uint64[] memory rewardsMultipliers = new uint64[](4);
        rewardsMultipliers[0] = 100;
        rewardsMultipliers[1] = 50;
        rewardsMultipliers[2] = 25;
        rewardsMultipliers[3] = 10;

        // WithdrawFees
        uint64[] memory withdrawFeeBlocks = new uint64[](4);
        withdrawFeeBlocks[0] = 0;
        withdrawFeeBlocks[1] = 100;
        withdrawFeeBlocks[2] = 1000;
        withdrawFeeBlocks[3] = 10_000;
        uint64[] memory withdrawFees = new uint64[](4);
        withdrawFees[0] = 15;
        withdrawFees[1] = 10;
        withdrawFees[2] = 5;
        withdrawFees[3] = 2;

        pool =
        new Pool(address(token1), deployer, 20, 10, rewardsMultiplierBlocks, rewardsMultipliers, withdrawFeeBlocks, withdrawFees, address(boosterPack));

        assertEq(pool.getBaseRateTokensPerBlock(), 20);
        assertEq(pool.getDepositFee(), 10);
        assertEq(pool.getDepositFeeRecipient(), deployer);
        assertEq(pool.getRewardsMultiplierBlockNumber(0), 100);
        assertEq(pool.getRewardsMultiplierBlockNumber(1), 200);
        assertEq(pool.getRewardsMultiplierBlockNumber(2), 300);
        assertEq(pool.getRewardsMultiplierBlockNumber(3), 400);
        assertEq(pool.getRewardsMultiplier(0), 100);
        assertEq(pool.getRewardsMultiplier(1), 50);
        assertEq(pool.getRewardsMultiplier(2), 25);
        assertEq(pool.getRewardsMultiplier(3), 10);
        assertEq(pool.getWithdrawFeeBlockNumber(0), 0);
        assertEq(pool.getWithdrawFeeBlockNumber(1), 100);
        assertEq(pool.getWithdrawFeeBlockNumber(2), 1000);
        assertEq(pool.getWithdrawFeeBlockNumber(3), 10_000);
        assertEq(pool.getWithdrawFee(0), 15);
        assertEq(pool.getWithdrawFee(1), 10);
        assertEq(pool.getWithdrawFee(2), 5);
        assertEq(pool.getWithdrawFee(3), 2);
    }

    function test_updateBaseRateTokensPerBlock() public {
        // Unhappy path Nº1 - Trying to update the variable without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.updateBaseRateTokensPerBlock(50);

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        pool.updateBaseRateTokensPerBlock(50);
        assertEq(pool.getBaseRateTokensPerBlock(), 50);

        vm.stopPrank();
    }

    function test_updateDepositFee() public {
        // Unhappy path Nº1 - Trying to update the variable without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.updateDepositFee(50);

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        pool.updateDepositFee(50);
        assertEq(pool.getDepositFee(), 50);

        vm.stopPrank();
    }

    function test_addRewardsMultiplier() public {
        // Unhappy path Nº1 - Trying to add a reward multiplier without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.addRewardsMultiplier(500, 5);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to add a reward multiplier with blockNumber = 0.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_BlockNumberZeroError()"));
        pool.addRewardsMultiplier(0, 5);

        // Unhappy path Nº3 - Being the Owner and trying to add a reward multiplier with multiplier = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_RewardsMultiplierZeroError()"));
        pool.addRewardsMultiplier(500, 0);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.addRewardsMultiplier(500, 5);
        assertEq(pool.getRewardsMultiplierBlockNumber(4), 500);
        assertEq(pool.getRewardsMultiplier(4), 5);

        vm.stopPrank();
    }

    function test_updateRewardsMultiplier() public {
        // Unhappy path Nº1 - Trying to update a reward multiplier without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.updateRewardsMultiplier(0, 500, 5);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to update a reward multiplier that does not exist.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_RewardsMultiplierDoesNotExistError()"));
        pool.updateRewardsMultiplier(5, 500, 5);

        // Unhappy path Nº3 - Being the Owner and trying to update a reward multiplier with blockNumber = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_BlockNumberZeroError()"));
        pool.updateRewardsMultiplier(0, 0, 5);

        // Unhappy path Nº4 - Being the Owner and trying to update a reward multiplier with multiplier = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_RewardsMultiplierZeroError()"));
        pool.updateRewardsMultiplier(0, 500, 0);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.updateRewardsMultiplier(0, 500, 5);
        assertEq(pool.getRewardsMultiplierBlockNumber(0), 500);
        assertEq(pool.getRewardsMultiplier(0), 5);

        vm.stopPrank();
    }

    function test_removeRewardsMultiplier() public {
        // Unhappy path Nº1 - Trying to remove a reward multiplier without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.removeRewardsMultiplier(0);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to delete a reward multiplier that does not exist.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_RewardsMultiplierDoesNotExistError()"));
        pool.removeRewardsMultiplier(5);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.removeRewardsMultiplier(0);
        assertEq(pool.getRewardsMultiplierBlockNumber(0), 0);
        assertEq(pool.getRewardsMultiplier(0), 0);

        vm.stopPrank();
    }

    function test_addWithdrawFee() public {
        // Unhappy path Nº1 - Trying to add a withdraw fee without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.addWithdrawFee(10_000, 2);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to add a withdraw fee with blockNumber = 0.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_BlockNumberZeroError()"));
        pool.addWithdrawFee(0, 2);

        // Unhappy path Nº3 - Being the Owner and trying to add a withdraw fee with fee = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeeZeroError()"));
        pool.addWithdrawFee(10_000, 0);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.addWithdrawFee(10_000, 2);
        assertEq(pool.getWithdrawFeeBlockNumber(4), 10_000);
        assertEq(pool.getWithdrawFee(4), 2);

        vm.stopPrank();
    }

    function test_updateWithdrawFee() public {
        // Unhappy path Nº1 - Trying to update a withdraw fee without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.updateWithdrawFee(0, 1, 50);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to update a withdraw fee that does not exist.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeeDoesNotExistError()"));
        pool.updateWithdrawFee(5, 0, 50);

        // Unhappy path Nº3 - Being the Owner and trying to update a withdraw fee with blockNumber = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_BlockNumberZeroError()"));
        pool.updateWithdrawFee(0, 0, 50);

        // Unhappy path Nº4 - Being the Owner and trying to update a withdraw fee with fee = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeeZeroError()"));
        pool.updateWithdrawFee(0, 1, 0);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.updateWithdrawFee(0, 1, 50);
        assertEq(pool.getWithdrawFeeBlockNumber(0), 1);
        assertEq(pool.getWithdrawFee(0), 50);

        vm.stopPrank();
    }

    function test_removeWithdrawFee() public {
        // Unhappy path Nº1 - Trying to remove a withdraw fee without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.removeWithdrawFee(0);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to delete a withdraw fee that does not exist.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeeDoesNotExistError()"));
        pool.removeWithdrawFee(5);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.removeWithdrawFee(0);
        assertEq(pool.getWithdrawFeeBlockNumber(0), 0);
        assertEq(pool.getWithdrawFee(0), 0);

        vm.stopPrank();
    }

    // TO-DO Separate from Pool Logic

    function test_deposit() public {
        // Unhappy path Nº1 - The user doesn't have enough funds to deposit.
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("Pool_NotEnoughBalanceToDepositError()"));
        pool.deposit(2000);

        // Happy path
        token1.approve(address(pool), 500);
        pool.deposit(500);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 500);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 0), 450);

        vm.stopPrank();
    }

    function test_deposit_multipleDeposits() public {
        vm.startPrank(user1);

        token1.approve(address(pool), 1000);
        pool.deposit(500);

        vm.warp(10 days);
        pool.deposit(300);
        pool.deposit(200);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 0);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 900);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 0), 450);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 1), 270);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 2), 180);

        vm.stopPrank();
    }

    function test_deposit_multiplePeriods() public {
        vm.startPrank(user1);

        token1.approve(address(pool), 1000);
        pool.deposit(500);

        vm.roll(150);
        pool.deposit(500);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 0);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 900);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), 1);
        assertEq(pool.getUserDepositAmount(user1, 0), 450);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), 150);
        assertEq(pool.getUserDepositAmount(user1, 1), 450);

        vm.stopPrank();
    }

    function test_deposit_poolPaused() public {
        // Set up
        vm.startPrank(deployer);

        pool.pause();

        vm.stopPrank();

        // Unhappy path Nº1 - The pool is paused.
        vm.startPrank(user1);
        token1.approve(address(pool), 500);

        vm.expectRevert(abi.encodeWithSignature("Pool_Paused()"));
        pool.deposit(500);

        vm.stopPrank();
    }

    function test_withdraw() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 500);
        pool.deposit(500);

        // Unhappy path Nº1 - The user doesn't have enough funds to withdraw.
        vm.expectRevert(abi.encodeWithSignature("Pool_NotEnoughAmountDepositedError()"));
        pool.withdraw(2000);

        // Happy path
        token1.approve(address(pool), 500);
        pool.withdraw(450);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 905);
        assertEq(token1.balanceOf(address(pool)), 0);
        assertEq(token1.balanceOf(deployer), 95);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 0);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);

        vm.stopPrank();
    }

    function test_withdraw_twoDeposits() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 1000);
        pool.deposit(500);
        pool.deposit(300);

        token1.approve(address(pool), 1000);
        pool.withdraw(600);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 800);
        assertEq(token1.balanceOf(address(pool)), 56);
        assertEq(token1.balanceOf(deployer), 144);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 75);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 1);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), block.number);
        assertEq(pool.getUserDepositAmount(user1, 1), 75);

        vm.stopPrank();
    }

    function test_withdraw_multipleDeposits() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 1000);
        pool.deposit(500);
        pool.deposit(300);
        pool.deposit(200);

        token1.approve(address(pool), 1000);
        pool.withdraw(600);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 600);
        assertEq(token1.balanceOf(address(pool)), 236);
        assertEq(token1.balanceOf(deployer), 164);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 255);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 1);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), block.number);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), block.number);
        assertEq(pool.getUserDepositAmount(user1, 1), 75);
        assertEq(pool.getUserDepositBlockNumber(user1, 2), block.number);
        assertEq(pool.getUserDepositAmount(user1, 2), 180);

        vm.stopPrank();
    }

    function test_withdraw_twoPeriods() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 1000);
        pool.deposit(500);
        vm.roll(150);
        pool.deposit(500);

        token1.approve(address(pool), 1000);
        pool.withdraw(600);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 600);
        assertEq(token1.balanceOf(address(pool)), 246);
        assertEq(token1.balanceOf(deployer), 154);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 255);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 1);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), 1);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), 150);
        assertEq(pool.getUserDepositAmount(user1, 1), 255);

        vm.stopPrank();
    }

    function test_withdraw_multiplePeriods() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 1000);
        pool.deposit(500);
        vm.roll(150);
        pool.deposit(300);
        vm.roll(1050);
        pool.deposit(200);

        token1.approve(address(pool), 1000);
        pool.withdraw(800);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 800);
        assertEq(token1.balanceOf(address(pool)), 40);
        assertEq(token1.balanceOf(deployer), 160);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 42);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 2);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), 1);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), 150);
        assertEq(pool.getUserDepositAmount(user1, 1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 2), 1050);
        assertEq(pool.getUserDepositAmount(user1, 2), 42);

        vm.stopPrank();
    }

    function test_withdraw_poolPaused() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.stopPrank();

        vm.startPrank(deployer);
        pool.pause();
        vm.stopPrank();

        // Happy path
        vm.startPrank(user1);
        token1.approve(address(pool), 500);
        vm.roll(250);
        pool.withdraw(450);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 905);
        assertEq(token1.balanceOf(address(pool)), 0);
        assertEq(token1.balanceOf(deployer), 95);

        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 0);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), 1);
        assertEq(pool.getUserDepositAmount(user1, 0), 0);

        vm.stopPrank();
    }

    function test_claimRewards() public {
        // Set up
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.roll(50);
        pool.claimRewards(user1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 98_499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 217_777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 97_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);

        vm.stopPrank();
    }

    function test_claimRewards_twoPeriods() public {
        // Set up
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);

        vm.roll(50);
        pool.claimRewards(user1);

        vm.roll(150);
        pool.claimRewards(user1);
        assertEq(token1.balanceOf(user1), 247_499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(pool.getRewardsPerToken(), 548_887);
        assertEq(pool.getLastBlockUpdated(), 150);
        assertEq(pool.getUserAccumRewards(user1), 246_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);

        vm.stopPrank();
    }

    function test_claimRewards_multipleDeposits() public {
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);

        vm.stopPrank();

        vm.startPrank(user2);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.roll(50);
        pool.claimRewards(user2);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 500);
        assertEq(token1.balanceOf(user2), 49_499);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getRewardsPerToken(), 108_888);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserAccumRewards(user2), 48_999);
        assertEq(pool.getUserAccumRewardsBP(user2), 0);
        assertEq(pool.getUserClaimableRewardsBP(user2), 0);
        assertEq(pool.getUserTotalAmountDeposited(user2), 450);

        vm.stopPrank();
    }

    function test_claimRewards_multipleDeposits_multiplePeriods() public {
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);

        vm.stopPrank();

        vm.startPrank(user2);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.roll(50);
        pool.claimRewards(user2);

        vm.roll(150);
        pool.claimRewards(user1);
        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 123_999);
        assertEq(token1.balanceOf(user2), 49_499);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getRewardsPerToken(), 274_443);
        assertEq(pool.getLastBlockUpdated(), 150);
        assertEq(pool.getUserAccumRewards(user1), 123_499);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserAccumRewards(user2), 48_999);
        assertEq(pool.getUserAccumRewardsBP(user2), 0);
        assertEq(pool.getUserClaimableRewardsBP(user2), 0);
        assertEq(pool.getUserTotalAmountDeposited(user2), 450);

        vm.stopPrank();
    }

    function test_claimRewards_withBoosterPack() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 100, 1000, 3);

        vm.stopPrank();

        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        boosterPack.setApprovalForAll(address(pool), true);
        pool.burnBP(1);
        vm.roll(50);
        pool.claimRewards(user1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 392_496);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 217_777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 97_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 293_997);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserActiveBoosterPack(user1), 1);
        assertEq(pool.getUsersWithBoosterPacks(0), user1);
        assertEq(pool.getRewardsPerTokenBoosterPack(user1), 217_777);

        vm.stopPrank();
    }

    function test_claimRewards_withBoosterPack_lateActivation() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 100, 1000, 3);

        vm.stopPrank();

        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        boosterPack.setApprovalForAll(address(pool), true);
        vm.roll(50);
        pool.burnBP(1);
        vm.roll(99);
        pool.claimRewards(user1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 490_496);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 435_554);
        assertEq(pool.getLastBlockUpdated(), 99);
        assertEq(pool.getUserAccumRewards(user1), 195_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 293_997);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserActiveBoosterPack(user1), 1);
        assertEq(pool.getUsersWithBoosterPacks(0), user1);
        assertEq(pool.getRewardsPerTokenBoosterPack(user1), 217_777);

        vm.stopPrank();
    }

    function test_claimRewards_withEndedBoosterPack() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 100, 1000, 3);

        vm.stopPrank();

        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        boosterPack.setApprovalForAll(address(pool), true);
        pool.burnBP(1);
        vm.roll(150);
        pool.claimRewards(user1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 841_499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 548_888);
        assertEq(pool.getLastBlockUpdated(), 150);
        assertEq(pool.getUserAccumRewards(user1), 246_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 594_000);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUsersWithBoosterPacks(0), address(0));
        assertEq(pool.getRewardsPerTokenBoosterPack(user1), 440_000);

        vm.stopPrank();
    }

    function test_claimRewards_withBoosterPack_multipleDeposits() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 100, 1000, 3);

        vm.stopPrank();

        vm.startPrank(user1);

        token1.approve(address(pool), 1000);
        pool.deposit(500);
        boosterPack.setApprovalForAll(address(pool), true);
        pool.burnBP(1);
        vm.roll(50);
        pool.deposit(300);
        pool.claimRewards(user1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 627_396);
        assertEq(token1.balanceOf(address(pool)), 720);
        assertEq(token1.balanceOf(deployer), 80);

        assertEq(pool.getRewardsPerToken(), 217_777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 156_799);
        assertEq(pool.getUserAccumRewardsBP(user1), 470_397);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 720);
        assertEq(pool.getUserActiveBoosterPack(user1), 1);
        assertEq(pool.getUsersWithBoosterPacks(0), user1);
        assertEq(pool.getRewardsPerTokenBoosterPack(user1), 217_777);

        vm.stopPrank();
    }

    function test_claimRewards_poolPaused() public {
        // Set up
        vm.startPrank(user1);
        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.roll(50);
        vm.stopPrank();

        vm.startPrank(deployer);
        pool.pause();
        vm.stopPrank();

        vm.roll(150);

        // Happy path - Get rewards from block 50
        pool.claimRewards(user1);

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 98_499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 217_777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 97_999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserClaimableRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);

        vm.stopPrank();
    }

    function test_burnBP() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 50, 100, 3);
        boosterPack.mint(user1, 2, 1, 50, 200, 3);

        vm.stopPrank();

        vm.startPrank(user1);

        // Unhappy path Nº1 - Trying to burn a BoosterPack that does not exist.
        vm.expectRevert(abi.encodeWithSignature("Pool_BPDoesNotExistBPError()"));
        pool.burnBP(3);

        // Unhappy path Nº2 - Trying to burn a BoosterPack that has already expired.
        vm.roll(150);
        vm.expectRevert(abi.encodeWithSignature("Pool_ExpiredBPError()"));
        pool.burnBP(1);

        // Happy path - BoosterPack exists, not expired and the user does not have an active BP.
        boosterPack.setApprovalForAll(address(pool), true);
        pool.burnBP(2);

        // Unhappy path Nº3 - Trying to burn a BoosterPack when the user has already one active.
        vm.expectRevert(abi.encodeWithSignature("Pool_OnlyOneActiveBPError()"));
        pool.burnBP(1);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(pool.getUserActiveBoosterPack(user1), 2);

        vm.stopPrank();
    }

    function test_burnBP_poolPaused() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.addWhitelistedAddrBP(address(pool));
        boosterPack.mint(user1, 1, 2, 50, 100, 3);
        pool.pause();

        vm.stopPrank();

        // Unhappy path Nº1 - The pool is paused.
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("Pool_Paused()"));
        pool.burnBP(1);

        vm.stopPrank();
    }

    function test_pausePool() public {
        // Unhappy path Nº1 - Trying to pause the Pool without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.pause();

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        pool.pause();
        assertEq(pool.getPaused(), true);

        vm.stopPrank();
    }

    function test_unpausePool() public {
        // Set up
        vm.startPrank(deployer);

        pool.pause();

        vm.stopPrank();

        // Unhappy path Nº1 - Trying to unpause the Pool without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        pool.unpause();

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        pool.unpause();
        assertEq(pool.getPaused(), false);

        vm.stopPrank();
    }
}
