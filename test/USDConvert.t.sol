// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "forge-std/Test.sol";
import {USDConvert} from "src/USDConvert.sol";


interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
    function load(address, bytes32) external returns (bytes32);
}

interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface VatLike {
    function wards(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function live() external view returns (uint256);
}


interface GemLike {
    function approve(address, uint256) external returns (bool);
}

interface DaiLike is GemLike {
    function balanceOf(address) external returns (uint256);
}

interface DSTokenLike {
    function balanceOf(address) external returns (uint256);
}

contract USDConvertTest is Test {
   
    USDConvert usdConvert;

    ChainlogLike          chainlog;
    VatLike                    vat;
    Hevm hevm;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));



    // Mainnet addresses
    address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address constant MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
    address constant MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function setUp() external {
        // DSS stuff
        chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
        hevm = Hevm(address(CHEAT_CODE));
        
        vat = VatLike(              chainlog.getAddress("MCD_VAT"));

        // Our contract
        usdConvert = new USDConvert(); 
    }

    // Filter function for fuzz testing
    function filter() internal {
    }

   
    function testSendGemUSDC() external {
        // TODO HEVM cheatcode

        /* hevm.store(
        * vat address
        * memory slot to update
        * value to update with
        ) */
        hevm.store(
            address(VAT),
            keccak256(abi.encode(address(usdConvert), uint256(0))),
            bytes32(uint256(1))
        );
        
        usdConvert.sendGem(MCD_PSM_USDC_A, USDC, address(this), 100);
        // Check balances
        //TODO Fuzz test as well as gas route test
    }

    function testHevm() external {
        hevm.store(
            address(VAT),
            keccak256(abi.encode(address(usdConvert), uint256(0))),
            bytes32(uint256(1))
        );
        
    }

    function testSendGemPAX() external {}

    function testSendGemGUSD() external {}

    function testSendFailsOnZeroBalance() external{

    }

    function testSendFailsOnTooHighAmount() external{
        
    }
    
}
