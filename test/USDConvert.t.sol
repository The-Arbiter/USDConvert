// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "forge-std/Test.sol";
import "src/USDConvert.sol"; // Import the file not the interfaces so we can use the interfaces


interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
    function load(address, bytes32) external returns (bytes32);
}

interface VatLike {
    function wards(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function live() external view returns (uint256);
    // Temporary
    function hope(address) external;
    function wish(address, address) external view returns (bool);
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
    PsmLike                    psm_USDC;
    PsmLike                    psm_PAX;
    PsmLike                    psm_GUSD;
    DaiLike                    dai;
    GemLike                    usdc;
    GemLike                    pax;
    GemLike                    gusd;


    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE = bytes20(uint160(uint256(keccak256('hevm cheat code'))));



    // Mainnet addresses (For reference)
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address constant MCD_PSM_GUSD_A = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
    address constant MCD_PSM_PAX_A = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address constant GUSD = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
    address constant MCD_JOIN_DAI = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    
    // Chainlog used for setup
    address constant CHAINLOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    function setUp() external {

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        /// @dev Chainlog address pulling gives: setUp failed reason="EvmError: Revert" contract=0x62d69f6867a0a084c6d313943dc22023bc263691
        // No idea why...
        //chainlog = ChainlogLike(CHAINLOG);
        /* bytes32 name = "MCD_VAT";
        uint example = chainlog.count();
        console2.log(example); */

        
        // Instantiate the stuff we need
        vat = VatLike(VAT);
        psm_USDC = PsmLike(MCD_PSM_USDC_A);
        psm_GUSD = PsmLike(MCD_PSM_GUSD_A); 
        psm_PAX = PsmLike(MCD_PSM_PAX_A);
        dai = DaiLike(DAI);
        //usdc = GemLike(AuthGemJoinLike(PsmLike(psm_USDC).gemJoin()).gem()); // Faster for testing to not use this, but should for final tests
        usdc = GemLike(USDC);
        pax = GemLike(PAX);
        gusd = GemLike(GUSD);

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
                console2.log("Found it");
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
        revert("Failed to find slot for AUTHing");
    }

    // Filter function for fuzz testing
    function filter() internal {
    }

   
    function testSendGemUSDC() external {

        // Store old balance
        uint256 oldBalance = usdc.balanceOf(address(this));
        uint256 amount = 100;

        // Auth usdConvert against the vat for testing only
        giveAuthAccess(VAT,address(usdConvert));
        if(AuthLike(VAT).wards(address(usdConvert)) != 1){
            revert("Auth not obtained on VAT");
        }
        
        // NOTE - Need to hope to allow DaiJoin to move on behalf of USDConvert
        vm.prank(address(usdConvert));
        vat.hope(MCD_JOIN_DAI);

        console2.log("All auth successful.");
        
        // Call sendGem. This will send some amount of tokens to this address.

        usdConvert.sendGem(MCD_PSM_USDC_A, address(this), amount);

        // Update balance
        uint256 newBalance = usdc.balanceOf(address(this));

        // Check 1 - The amount sent is correct
        if(newBalance - oldBalance != amount * (10 ** usdc.decimals())){
            console2.log("Old balance",oldBalance);
            console2.log("New balance",newBalance);
            console2.log("Amount",amount * (10 ** usdc.decimals()));
            revert("Incorrect balance sent!");
        }
        // Check 2 - The surplus buffer has decreased by a corresponding amount

        // Check 3 - The caller has no residual balance for either currency

        
    }

    //TODO Fuzz test as well as gas route test

    function testSendGemPAX() external {}

    function testSendGemGUSD() external {}

    function testSendFailsOnZeroBalance() external{

    }

    function testSendFailsOnTooHighAmount() external{
        
    }
    
}
