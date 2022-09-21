// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import {USDConvert} from "src/USDConvert.sol";

contract USDConvertTest is Test {
   
    USDConvert usdConvert;

    address GoerliPSM = address(0);
    address GoerliDAI = address(0);
    address GoerliUSDC = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557;

    function setUp() external {
        usdConvert = new USDConvert(GoerliPSM,GoerliDAI,GoerliUSDC);
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSendUSDC() external {
        //TODO
    }

    function testSendFailsOnZeroBalance() external{

    }

    function testSendFailsOnTooHighAmount() external{
        
    }
    
}
