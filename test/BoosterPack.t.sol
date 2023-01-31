// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/BoosterPack.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract BoosterPackTest is Test {
    BoosterPack public boosterPack;
    string baseURI = "https://token-cdn-domain/{id}.json";

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

        boosterPack = new BoosterPack(baseURI);

        vm.stopPrank();
    }

    function test_addWhitelistedAddrBP() public {
        // Unhappy path Nº1 - Trying to mint the token without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        boosterPack.addWhitelistedAddrBP(user1);

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(user1);
        assertEq(boosterPack.getWhitelistedAddrBP(user1), true);

        vm.stopPrank();
    }

    function test_removeWhitelistedAddrBP() public {
        // Unhappy path Nº1 - Trying to mint the token without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        boosterPack.removeWhitelistedAddrBP(user1);

        vm.stopPrank();

        // Happy path - Being the Owner.
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(user1);
        assertEq(boosterPack.getWhitelistedAddrBP(user1), true);

        boosterPack.removeWhitelistedAddrBP(user1);
        assertEq(boosterPack.getWhitelistedAddrBP(user1), false);

        vm.stopPrank();
    }

    function test_setAttributes() public {
        // Unhappy path Nº1 - Trying to change a BoosterPack attributes without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        boosterPack.setAttributes(1, 7 days, uint64(block.timestamp + 30 days), 2);

        vm.stopPrank();

        // Happy path - Being the Owner.
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.mint(deployer, 1, 1, 7 days, uint64(block.timestamp + 30 days), 2);

        boosterPack.setAttributes(1, 8 days, uint64(block.timestamp + 60 days), 3);
        assertEq(boosterPack.getDuration(1), 8 days);
        assertEq(boosterPack.getExpirationDate(1), uint64(block.timestamp + 60 days));
        assertEq(boosterPack.getMultiplier(1), 3);

        vm.stopPrank();
    }

    function test_mint() public {
        // Unhappy path Nº1 - Trying to mint a Booster Pack without being whitelisted.
        vm.startPrank(deployer);

        vm.expectRevert(abi.encodeWithSignature("BoosterPack_AddressNotAllowedToMintError()"));
        boosterPack.mint(deployer, 1, 1, 7 days, uint64(block.timestamp + 30 days), 2);

        // Happy path - Mint a Booster Pack being whitelisted.
        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.mint(deployer, 1, 1, 7 days, uint64(block.timestamp + 30 days), 2);

        assertEq(boosterPack.balanceOf(deployer, 1), 1);

        vm.stopPrank();
    }

    function test_burn() public {
        // Set up
        vm.startPrank(deployer);

        boosterPack.addWhitelistedAddrBP(deployer);
        boosterPack.mint(deployer, 1, 1, 7 days, uint64(block.timestamp + 30 days), 2);
        assertEq(boosterPack.balanceOf(deployer, 1), 1);

        vm.stopPrank();

        // Unhappy path Nº1 - Trying to burn a Booster Pack a Booster Pack without being whitelisted.
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("BoosterPack_AddressNotAllowedToBurnError()"));
        boosterPack.burn(1, 1);

        vm.stopPrank();

        // Happy path - Burn a Booster Pack being whitelisted.
        vm.startPrank(deployer);

        boosterPack.burn(1, 1);
        assertEq(boosterPack.balanceOf(deployer, 1), 0);

        vm.stopPrank();
    }
}
