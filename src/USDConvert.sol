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

import "dss-exec-lib/DssExecLib.sol"; // For sendPaymentFromSurplusBuffer

interface DaiLike { // Dai is not DSToken (TODO confirm)
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface GemLike {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external returns (uint256);
}

interface PsmLike {
  function gemJoin() external view returns (address); 
  function tout() external view returns (uint256);
  function buyGem(address usr, uint256 gemAmt) external;
}

interface AuthGemJoinLike {
    function gem() external view returns (address);
}

interface VatLike {
    function dai(address) external view returns (uint256);
    // Hope, since this is a separate repo to dss-exec-lib (Can remove if not needed)
    function hope(address) external;
}

interface VowLike {
    function Sin() external returns (uint256);
}


/** 
*   @title USDConvert will do the following:
*   
*   0) Checks for precision and value mistakes
*   1) Send DAI from the surplus buffer to the current address
*   2) Sells DAI for some `amt` of underlying Gem token via the PSM's BuyGem function
*   3) Sends all purchased Gem to an address
*   
*/
contract USDConvert {
 
  /*****************/
  /*** Constants ***/
  /*****************/
  address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
  uint256 constant WAD = 10 ** 18;
  uint256 constant RAD = 10 ** 45;

  // Helper to allow this to drag and drop into DssExecLib
  function getChangelogAddress(bytes32 _key) public view returns (address) {
    return ChainlogLike(LOG).getAddress(_key);
  }

  /****************************/
  /*** Core Address Helpers ***/
  /****************************/
  function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
  function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
  function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }


  // NOTE: tout fees are accounted for *outside* of this function to allow spells to be more readable
  // NOTE: this operates on assumption that 1 Gem is 1 DAI - we may need to change this in the future (OK for now)
  /**
        @dev Swap DAI from the surplus buffer to Gem using the corresponding PSM and send it to a recipient
        @param _psm          Address of the PSM instance we are referring to (not the joiner)
        @param _dst          Destination address to receive the Gem
        @param _amt          Amount of *Gem* token to be sent to the destination address
        @return              Returns true on success
  */
  function sendGem(address _psm, address _dst, uint256 _amt) external returns (bool){
    require(_amt < (VatLike(vat()).dai(vow()) - VowLike(vow()).Sin())/RAD); // "LibDssExec/exceeds-surplus-buffer"
    DssExecLib.sendPaymentFromSurplusBuffer(address(this), _amt);
    address gem = AuthGemJoinLike(PsmLike(_psm).gemJoin()).gem();
    DaiLike(dai()).approve(_psm, _amt * WAD); 
    PsmLike(_psm).buyGem(address(this), _amt * (10 ** GemLike(gem).decimals())); 
    GemLike(gem).transfer(_dst,GemLike(gem).balanceOf(address(this))); //TODO this can be used to attack this
    return true;
  }

  /**
  Security analysis:
  - BuyGem may break if 1:1 variance breaks
  - Guardrails for precision and > SB size are in place
  - Malicious PSM address pointing to a malicious gemJoin would allow for RCE style attack:
    We can derive the address 'gem' by using the interface AuthGemJoin on the return from GemJoin 
    and then calling Gem on that. That relies on the usage of the spell being used VERY carefully 
    or malicious calls can be made.
  */

}
