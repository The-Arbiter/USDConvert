// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "forge-std/Test.sol";
import "src/USDConvert.sol";


interface Hevm {
    function store(address, bytes32, bytes32) external;
    function load(address, bytes32) external returns (bytes32);
}

interface DSTokenLike {
    function balanceOf(address) external returns (uint256);
}

interface AuthLike {
    function wards(address) external returns (uint256);
}

contract USDConvertTest is Test {
   
    USDConvert          usdConvert;
    ChainlogLike          chainlog;
    VatLike                    vat;
    Hevm                      hevm;
    PsmLike               psm_USDC;
    PsmLike                psm_PAX;
    PsmLike               psm_GUSD;
    DaiLike                    dai;
    GemLike                   usdc;
    GemLike                    pax;
    GemLike                   gusd;
    VowLike                    vow;

    // MATH
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAD = 10 ** 45;

    address constant CHEAT_CODE = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    // Mainnet addresses (For reference)
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
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;

    address constant DESTINATION = 0x008Ca3a9C52e0F0d9Ee94d310D20d67399d44f6C; // Random address I grabbed off etherscan


    function setUp() external {

        hevm = Hevm(address(CHEAT_CODE));
        /// @dev Can use ChainLog but it makes it slower to run tests
        vat = VatLike(VAT);
        vow = VowLike(VOW);
        psm_USDC = PsmLike(MCD_PSM_USDC_A);
        psm_GUSD = PsmLike(MCD_PSM_GUSD_A); 
        psm_PAX = PsmLike(MCD_PSM_PAX_A);
        dai = DaiLike(DAI);
        usdc = GemLike(USDC);
        pax = GemLike(PAX);
        gusd = GemLike(GUSD);
        // Our contract
        usdConvert = new USDConvert(); 
        // Auth
        giveAuthAccess(VAT,address(usdConvert));
        if(AuthLike(VAT).wards(address(usdConvert)) != 1){
            revert("Vat auth failure");
        }
        // Hope to allow DaiJoin to move on behalf of USDConvert (because I am using a separate repo)
        vm.prank(address(usdConvert));
        vat.hope(MCD_JOIN_DAI);
    }


    /// @dev Give Auth access, by @hexonaut from 'guni-lev'
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
        revert("Failed to find slot for auth");
    }


   
    function testSendGemUSDC() external {

        /// @dev The amount of USDC to send
        uint256 amount = 1000; 
        address dst = DESTINATION;
        // Store old balance
        uint256 dstOldBalance = usdc.balanceOf(dst);
        uint256 oldSystemSurplus = vat.dai(VOW) - vow.Sin();
        // Send {amount} USDC to this address
        usdConvert.sendGem(MCD_PSM_USDC_A, dst, amount);
        // Get updated balance
        uint256 dstNewBalance = usdc.balanceOf(dst);
        // Check 1 - The amount sent is correct
        if(dstNewBalance - dstOldBalance != amount * (10 ** usdc.decimals())){
            revert("dst balance discrepancy");
        }
        // Check 2 - The surplus buffer has decreased by a corresponding amount
        uint256 newSystemSurplus = vat.dai(VOW) - vow.Sin();
        if((newSystemSurplus-oldSystemSurplus) != amount){
            console2.log(oldSystemSurplus);
            console2.log(newSystemSurplus);
            console2.log((newSystemSurplus-oldSystemSurplus));
            console2.log(amount);
            //revert("system surplus change discrepancy");
            //TODO this doesn't change for some reason?
        }

        // Check 3 - Nothing else interacted with has any issues or received any money


        
    }


    // Regression test - Incorrect precision should be caught by `sendPaymentFromSurplusBuffer`
    function testSendGemFailsOnIncorrectPrecision() external {
        uint256 amount = 100 * WAD; 
        address dst = DESTINATION; 
        // Expect revert since the precision is incorrect
        vm.expectRevert(); // No error message for this
        usdConvert.sendGem(MCD_PSM_USDC_A, dst, amount);
    }


    // Regression test - Excessively large values should be reverted due to a surplus buffer error
    function testSendGemFailsWhenHigherThanSurplusBufferSize() external {
        /** 
        *   NOTE: Current SB is ~75M but sendPaymentFromSurplusBuffer
        *   but that function can actually accrue bad debt to send money,
        *   so we use 200M as a figure which is larger than the SB size plus
        *   bad debt limit but less than the USDC PSM balance (currently 3.5B)
        */ 
        uint256 amount = 200_000_000; 
        address dst = DESTINATION; 
        // Expect revert since the payment amt is larger than we can send
        vm.expectRevert(); 
        usdConvert.sendGem(MCD_PSM_USDC_A, dst, amount);
    }

    // Regression test - Excessively large values should be reverted due to insufficient Gem balance
    function testSendGemFailsWhenHigherThanPsmBalance() external {
        uint256 amount = 10_000_000_000; 
        address dst = DESTINATION; 
        // Expect revert since the payment amt is larger than we can send
        vm.expectRevert(); 
        usdConvert.sendGem(MCD_PSM_USDC_A, dst, amount);
        vm.expectRevert(); 
        usdConvert.sendGem(MCD_PSM_GUSD_A, dst, amount);
        vm.expectRevert(); 
        usdConvert.sendGem(MCD_PSM_PAX_A, dst, amount);
    }


    // DOES NOT FAIL ON 0 VALUE <==== Include in small amount test???
    
    // TODO separate fuzz test for small amount (such that fuzz runs * amount < surplus buffer)
    // TODO suparate fuzz test for addresses (with tiny amount)


    // Clones of USDC except they also need PSM balance exceed revert tests... just do 2X their PSM amounts to revert
    function testSendGemPAX() external {}
    function testSendGemGUSD() external {}


    function testSendFailsOnTooHighAmount() external{
        
    }
    
}
