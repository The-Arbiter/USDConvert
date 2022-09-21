// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "forge-std/Test.sol";

import {USDConvert} from "src/USDConvert.sol";

contract USDConvertTest is Test {
   
    USDConvert usdConvert;

    address MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
    address MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() external {
        usdConvert = new USDConvert(); 
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
