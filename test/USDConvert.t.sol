// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "forge-std/Test.sol";
import "src/USDConvert.sol"; // Import the file not the interfaces so we can use the interfaces


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

interface PSMLike {
    function gemJoin() external view returns (address);
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}


interface DSTokenLike {
    function balanceOf(address) external returns (uint256);
}

interface AuthLike {
    function wards(address) external returns (uint256);
}

contract USDConvertTest is Test {
   
    USDConvert usdConvert;

    ChainlogLike          chainlog;
    VatLike                    vat;
    Hevm                      hevm;
    PSMLike                    psm_USDC;
    PSMLike                    psm_PAX;
    PSMLike                    psm_GUSD;


    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE = bytes20(uint160(uint256(keccak256('hevm cheat code'))));



    // Mainnet addresses (For reference)
    address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address constant MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
    address constant MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    // Chainlog used for setup
    address constant CHAINLOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    function setUp() external {
        // DSS stuff
        chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
        hevm = Hevm(address(CHEAT_CODE));
        
        // Instantiate the stuff we need
        vat = VatLike(chainlog.getAddress("MCD_VAT"));
        psm_USDC = PSMLike(chainlog.getAddress("MCD_PSM_USDC_A"));
        psm_PAX = PSMLike(chainlog.getAddress("MCD_PSM_PAX_A"));
        psm_GUSD = PSMLike(chainlog.getAddress("MCD_PSM_GUSD_A"));

        // Our contract
        usdConvert = new USDConvert(); 
    }


    /// @dev Give Auth access, by hexonaut from 'guni-lev'
    function giveAuthAccess (address _base, address target) internal {
        AuthLike base = AuthLike(_base);

        // Edge case - ward is already set
        if (base.wards(target) == 1) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = hevm.load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            hevm.store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(1))
            );
            if (base.wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    // Filter function for fuzz testing
    function filter() internal {
    }

   
    function testSendGemUSDC() external {
        // TODO HEVM cheatcode

        // Auth usdConvert against the vat for testing only
        giveAuthAccess(address(vat),address(usdConvert));
        usdConvert.sendGem(MCD_PSM_USDC_A, address(this), 100);
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
