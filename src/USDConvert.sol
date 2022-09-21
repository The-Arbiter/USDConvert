/*
  _    _  _____ _____   _____                          _   
 | |  | |/ ____|  __ \ / ____|                        | |  
 | |  | | (___ | |  | | |     ___  _ ____   _____ _ __| |_ 
 | |  | |\___ \| |  | | |    / _ \| '_ \ \ / / _ \ '__| __|
 | |__| |____) | |__| | |___| (_) | | | \ V /  __/ |  | |_ 
  \____/|_____/|_____/ \_____\___/|_| |_|\_/ \___|_|   \__|
                                                                                                               
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// Using separate interfaces for clarity
interface DaiLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface GemLike {
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface PsmLike {
  function tout() external view returns (uint256);
  function buyGem(address usr, uint256 gemAmt) external;
}


/** 
*   @title USDConvert will do the following
*
*   1) Takes DAI from the current address
*   2) Redeems DAI for underlying USDC via the PSM
*   3) Sends all redeemed USDC to an address
*   
*/
contract USDConvert {
  
  // ADDRESSES 
  address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
  address constant MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
  address constant MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  // MATH
  uint256 constant WAD = 10 ** 18;

  //constructor() {}


  /**
  *   Function allowing convenient disbursement of USDC
  *   TODO uint or uint256 for input type? What is convention? I see various types...
  *   @param psm => PSM instance we are referring to (USDC-A, GUSD-A, USDP-A. etc.)
  *   @param gem => Collateral token address
  *   @param dst => Destination address
  *   @param amt => Amount to be transferred (USDC amount)
  *   returns `true` on success
  */
  function sendGem(address psm, address gem, address dst, uint256 amt) external returns (bool){

    // NOTE: tout is accounted for *outside* of this function to allow spells to be more understandable.

    // TODO this operates on assumption that 1USDC is 1 DAI - we may need to change this <--- This is OK? PSM Looks like it does too..

    // Get the toll out value (tout can change so we need to check it every time)
    

    // Give ourself / ensure we have enough DAI for this
    DssExecLib.sendPaymentFromSurplusBuffer(address(this), amt * WAD);

    // 2) Redeem DAI for USDC via the PSM

    // Approve the PSM to spend our DAI
    DaiLike(DAI).approve(psm, amt * WAD);
    uint256 decimals = GemLike(gem).decimals(); //TODO inline 
    // Buy GEM with DAI
    PsmLike(psm).buyGem(address(this), amt * (10 ** decimals)); 

    // 3) Send all of our USDC to the destination

    // Get our current balance
    uint256 all = GemLike(gem).balanceOf(address(this));  //TODO inline
    // Send it to `dst`
    GemLike(gem).transfer(dst,all);
    
    // Return `true` on success
    return true;
  }


}
