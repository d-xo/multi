// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Multi} from "../src/Multi.sol";

contract MultiTest is Test {
    Multi public multi;

    function setUp() public {
        multi = new Multi();
    }

    function test_trivial() public pure {
        assert(true);
    }
}
