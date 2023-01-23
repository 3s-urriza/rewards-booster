// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/ERC20/Token1.sol";
import "src/ERC20/Token2.sol";
import "src/Pool.sol";
import "src/TheToken.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract PoolTest is Test { // TO-DO Fixture
    Pool public pool;
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
        withdrawFeeBlocks[3] = 10000;
        uint64[] memory withdrawFees = new uint64[](4);
        withdrawFees[0] = 15;
        withdrawFees[1] = 10;
        withdrawFees[2] = 5;
        withdrawFees[3] = 2;

        pool = new Pool(address(token1), deployer, 20, 10, rewardsMultiplierBlocks, rewardsMultipliers, withdrawFeeBlocks, withdrawFees);

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
        pool.updateRewardsMultiplier(0, 500, 5);

        // Unhappy path Nº4 - Being the Owner and trying to update a reward multiplier with multiplier = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_RewardsMultiplierZeroError()"));
        pool.updateRewardsMultiplier(0, 500, 5);

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
        pool.addWithdrawFee(10000, 2);

        vm.stopPrank();

        // Unhappy path Nº2 - Being the Owner and trying to add a withdraw fee with blockNumber = 0.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("Pool_BlockNumberZeroError()"));
        pool.addWithdrawFee(0, 2);

        // Unhappy path Nº3 - Being the Owner and trying to add a withdraw fee with fee = 0.
        vm.expectRevert(abi.encodeWithSignature("Pool_WithdrawFeeZeroError()"));
        pool.addWithdrawFee(10000, 0);

        // Happy path - Being the Owner and passing the correct parameters.
        pool.addWithdrawFee(10000, 2);
        assertEq(pool.getWithdrawFeeBlockNumber(4), 10000);
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
        assertEq(pool.getUserTotalAmountDeposited(user1), 900);
        assertEq(pool.getUserActiveBoosterPack(user1), 0);
        assertEq(pool.getUserNextDepositIdToRemove(user1), 0);
        assertEq(pool.getUserDepositBlockNumber(user1, 0), 1);
        assertEq(pool.getUserDepositAmount(user1, 0), 450);
        assertEq(pool.getUserDepositBlockNumber(user1, 1), 150);
        assertEq(pool.getUserDepositAmount(user1, 1), 450);

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

    function test_claimRewards() public {
        // Set up
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);
        vm.roll(50);
        pool.claimRewards();

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 98499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        assertEq(pool.getRewardsPerToken(), 217777);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 97999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);

        vm.stopPrank();
    }

    function test_claimRewards_twoPeriods() public {
        // Set up
        vm.startPrank(user1);

        token1.approve(address(pool), 500);
        pool.deposit(500);

        vm.roll(50);
        pool.claimRewards();

        vm.roll(150);
        pool.claimRewards();
        assertEq(token1.balanceOf(user1), 247499);
        assertEq(token1.balanceOf(address(pool)), 450);
        assertEq(token1.balanceOf(deployer), 50);

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(pool.getRewardsPerToken(), 548887);
        assertEq(pool.getLastBlockUpdated(), 150);
        assertEq(pool.getUserAccumRewards(user1), 246999);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
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
        pool.claimRewards();

        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 500);
        assertEq(token1.balanceOf(user2), 49499);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getRewardsPerToken(), 108888);
        assertEq(pool.getLastBlockUpdated(), 50);
        assertEq(pool.getUserAccumRewards(user1), 0);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserAccumRewards(user2), 48999);
        assertEq(pool.getUserAccumRewardsBP(user2), 0);
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
        pool.claimRewards();

        vm.stopPrank();

        vm.startPrank(user1);
        vm.roll(150);
        pool.claimRewards();
        vm.stopPrank();

        vm.startPrank(deployer);

        assertEq(token1.balanceOf(user1), 123999);
        assertEq(token1.balanceOf(user2), 49499);
        assertEq(token1.balanceOf(address(pool)), 900);
        assertEq(token1.balanceOf(deployer), 100);

        assertEq(pool.getRewardsPerToken(), 274443);
        assertEq(pool.getLastBlockUpdated(), 150);
        assertEq(pool.getUserAccumRewards(user1), 123499);
        assertEq(pool.getUserAccumRewardsBP(user1), 0);
        assertEq(pool.getUserTotalAmountDeposited(user1), 450);
        assertEq(pool.getUserAccumRewards(user2), 48999);
        assertEq(pool.getUserAccumRewardsBP(user2), 0);
        assertEq(pool.getUserTotalAmountDeposited(user2), 450);

        vm.stopPrank();
    }

    function test_burnBP() public {

    }

    function test_pausePool() public {

    }

}