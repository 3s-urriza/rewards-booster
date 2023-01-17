// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/TheToken.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract TheTokenTest is Test {
    TheToken public token;

    address public deployer = vm.addr(1500);
    address public user1 = vm.addr(1501);
    address public user2 = vm.addr(1502);

    function setUp() public {
        // Label addresses
        vm.label(deployer, "Deployer");
        vm.label(user1, "User 1");
        vm.label(user2, "User 2");

        vm.startPrank(deployer);

        token = new TheToken();

        vm.stopPrank();
    }

    function test_mint() public {
        // Unhappy path Nº1 - Trying to mint the token without being the Owner.
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(user1, 10);

        vm.stopPrank();

        // Happy path - Being the Owner
        vm.startPrank(deployer);

        token.mint(deployer, 10);
        assertEq(token.balanceOf(deployer), 10);

        vm.stopPrank();
    }
}
