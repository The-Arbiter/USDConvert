/*
  _    _  _____ _____   _____                          _   
 | |  | |/ ____|  __ \ / ____|                        | |  
 | |  | | (___ | |  | | |     ___  _ ____   _____ _ __| |_ 
 | |  | |\___ \| |  | | |    / _ \| '_ \ \ / / _ \ '__| __|
 | |__| |____) | |__| | |___| (_) | | | \ V /  __/ |  | |_ 
  \____/|_____/|_____/ \_____\___/|_| |_|\_/ \___|_|   \__|
                                                                                                               
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol"; //TODO This is where the DssExecLib function is???

// Using separate interfaces for clarity <=== TODO Replace these with ERC20 interfaces?
interface DaiLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface GemLike {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface PsmLike {
  function gemJoin() external view returns (address); 
  function tout() external view returns (uint256);
  function buyGem(address usr, uint256 gemAmt) external;
}

interface AuthGemJoinLike {
    function gem() external view returns (address);
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
  
  // ADDRESSES (TODO Remove later)
  address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
  address constant MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
  address constant MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  // NOTE: tout is accounted for *outside* of this function to allow spells to be more understandable.
  // NOTE: this operates on assumption that 1USDC is 1 DAI - we may need to change this (OK for now)


  // MATH
  uint256 constant WAD = 10 ** 18;

  /**
  *   Function allowing convenient disbursement of USDC
  *   TODO uint or uint256 for input type? What is convention? I see various types...
  *   @param psm => PSM instance we are referring to (USDC-A, GUSD-A, PAX-A. etc.)
  *   gem => Collateral token address (Derived from PSM)
  *   @param dst => Destination address
  *   @param amt => Amount to be transferred (USDC amount)
  *   returns `true` on success
  */
  function sendGem(address psm, address dst, uint256 amt) external returns (bool){

    // 1) Get the required DAI from the surplus buffer
    DssExecLib.sendPaymentFromSurplusBuffer(address(this), amt * WAD); //TODO make this an internal call.
    // 2) Redeem DAI for USDC via the PSM

    // Get the gem address by calling 'gem' on the gemJoin contract;
    address gem = AuthGemJoinLike(PsmLike(psm).gemJoin()).gem();

    DaiLike(DAI).approve(psm, amt * WAD); // Approve the PSM to spend our DAI
    PsmLike(psm).buyGem(address(this), amt * (10 ** GemLike(gem).decimals())); // Buy GEM with DAI

    // 3) Send all of our GEM to the destination
    uint256 all = GemLike(gem).balanceOf(address(this));  //TODO inline // Get our current balance
    GemLike(gem).transfer(dst,all); // Send it to `dst`
    // Return `true` on success
    return true;
    
  }

  /**
  Security analysis:
  - If we do not control this address, then it can affect surpluis buffer funds
  - BuyGem may break if 1:1 variance breaks
  - 'All' works to drain excess funds from this (win win) but if something breaks it'll cause an issue... should consider it...
  
  
   
  
   We can derive the address 'gem' by using the interface AuthGemJoin on the return from GemJoin and then calling Gem on that.
   That relies on the usage of the spell being used VERY carefully or malicious calls can be made.
   
    */




  constructor() public {
  }


}
