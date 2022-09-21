// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import {USDConvert} from "src/USDConvert.sol";

contract USDConvertTest is Test {
   
    USDConvert usdConvert;

    function setUp() external {
        usdConvert = new USDConvert();
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSetGm() external {
    }
    
}
