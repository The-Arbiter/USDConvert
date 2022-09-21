/*
  _    _  _____ _____   _____                          _   
 | |  | |/ ____|  __ \ / ____|                        | |  
 | |  | | (___ | |  | | |     ___  _ ____   _____ _ __| |_ 
 | |  | |\___ \| |  | | |    / _ \| '_ \ \ / / _ \ '__| __|
 | |__| |____) | |__| | |___| (_) | | | \ V /  __/ |  | |_ 
  \____/|_____/|_____/ \_____\___/|_| |_|\_/ \___|_|   \__|
                                                                                                               
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// Using separate interfaces for clarity
interface DaiLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

/// @dev This is UsdcLike because we have the decimals hardcoded, so it is not all gem types
interface UsdcLike {
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
  address PSM_USDC_A = address(0);
  address DAI_ADDRESS = address(0);
  address USDC_ADDRESS = address(0);

  // MATH
  uint256 constant WAD = 10 ** 18;

  constructor(
    address PSM,
    address USDC,
    address DAI
    )
  {
    PSM_USDC_A = PSM;
    DAI_ADDRESS = DAI;
    USDC_ADDRESS = USDC;

  }


  /**
  *   Function allowing convenient disbursement of USDC
  *   TODO uint or uint256 for input type? What is convention? I see various types...
  *   @param dst => destination address
  *   @param amt => amount to be transferred (USDC amount)
  *   returns `true` on success
  */
  function pushUSDC(address dst, uint256 amt) external returns (bool) {

    // TODO this operates on assumption that 1USDC is 1 DAI - we may need to change this <--- This is OK? PSM Looks like it does too..

    // Get the toll out value (tout can change so we need to check it every time)
    uint256 tout = PsmLike(PSM_USDC_A).tout();

    // Give ourself / ensure we have enough DAI for this

    // GIVE OURSELF sendPaymentFromSurplusBuffer(address(this), amt * (tout + WAD)); TODO This will be how it is actually done

    // ENSURE sufficient balance
    require(DaiLike(DAI_ADDRESS).balanceOf(msg.sender) >= amt * (tout + WAD), "Dai/insufficient-balance"); 

    // 2) Redeem DAI for USDC via the PSM

    // Approve the PSM to spend our DAI
    DaiLike(DAI_ADDRESS).approve(PSM_USDC_A, amt * (tout + WAD));
    // Buy USDC with DAI
    PsmLike(PSM_USDC_A).buyGem(address(this), amt * (10**6)); // NOTE: 10^6 decimals means that this is hardcoded for USDC

    // 3) Send all of our USDC to the destination

    // Get our current balance
    uint256 all = UsdcLike(USDC_ADDRESS).balanceOf(address(this));
    // Send it to `dst`
    UsdcLike(USDC_ADDRESS).transfer(dst,all);
    
    // Return `true` on success
    return true;
  }
}
