// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";

import { Greeter } from "src/Greeter.sol";

contract GreeterTest is Test {
    Greeter greeter;

    event GMEverybodyGM();

    function setUp() external {
        greeter = new Greeter("gm");
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSetGm() external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        greeter.setGreeting("gm gm");

        // Expect the GMEverybodyGM event to be fired
        vm.expectEmit(true, true, true, true);
        emit GMEverybodyGM();
        // slither-disable-next-line unused-return
        greeter.gm("gm gm");

        // Expect the gm() call to revert
        vm.expectRevert(abi.encodeWithSignature("BadGm()"));
        // slither-disable-next-line unused-return
        greeter.gm("gm");
    }
}
