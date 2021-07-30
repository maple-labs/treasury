// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { IERC20 }        from "../../modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC20 }         from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Util }          from "../../modules/util/contracts/Util.sol";
import { IMapleGlobals } from "../../modules/globals/contracts/interfaces/IMapleGlobals.sol";
import { MapleGlobals }  from "../../modules/globals/contracts/MapleGlobals.sol";
import { DSTest }        from "../../modules/ds-test/src/test.sol";

import { Governor }    from "./accounts/Governor.sol";
import { GlobalAdmin } from "./accounts/GlobalAdmin.sol";
import { MapleTreasury } from "../MapleTreasury.sol";

contract MapleToken is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {

    }

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function updateFundsReceived() external {
        // Todo: implementation
    }

}

contract MapleTreasuryTest is DSTest {

    Governor               realGov; 
    Governor               fakeGov;
    MapleTreasury         treasury;
    MapleGlobals           globals;
    GlobalAdmin    realGlobalAdmin;
    MapleToken                 mpl;

    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  // Uniswap V2 Router
    address constant USDC                 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {

        realGlobalAdmin = new GlobalAdmin();
        realGov         = new Governor();
        fakeGov         = new Governor();
        mpl             = new MapleToken("Maple", "MPL");
        globals         = new MapleGlobals(address(realGov), address(mpl), address(realGlobalAdmin));
        treasury        = new MapleTreasury(address(mpl), USDC, UNISWAP_V2_ROUTER_02, address(globals));
        
        // mint("WBTC", address(this),  10 * BTC);
        // mint("WETH", address(this),  10 ether);
        // mint("DAI",  address(this), 100 ether);
        // mint("USDC", address(this), 100 * USD);
    }

    function test_setGlobals() public {
        IMapleGlobals globals2 = fakeGov.createGlobals(address(mpl));               // Create upgraded MapleGlobals

        assertEq(address(treasury.globals()), address(globals));

        assertTrue(!fakeGov.try_setGlobals(address(treasury), address(globals2)));  // Non-governor cannot set new globals

        globals2 = realGov.createGlobals(address(mpl));                             // Create upgraded MapleGlobals

        assertTrue(realGov.try_setGlobals(address(treasury), address(globals2)));   // Governor can set new globals
        assertEq(address(treasury.globals()), address(globals2));                   // Globals is updated
    }

    // function test_withdrawFunds() public {
    //     assertEq(IERC20(USDC).balanceOf(address(treasury)), 0);

    //     IERC20(USDC).transfer(address(treasury), 100 * USD);

    //     assertEq(IERC20(USDC).balanceOf(address(treasury)), 100 * USD);
    //     assertEq(IERC20(USDC).balanceOf(address(gov)),         0);

    //     assertTrue(!fakeGov.try_reclaimERC20_treasury(USDC, 40 * USD));  // Non-governor can't withdraw
    //     assertTrue(     gov.try_reclaimERC20_treasury(USDC, 40 * USD));

    //     assertEq(IERC20(USDC).balanceOf(address(treasury)), 60 * USD);  // Can be distributed to MPL holders
    //     assertEq(IERC20(USDC).balanceOf(address(gov)), 40 * USD);  // Withdrawn to MapleDAO address for funding
    // }

    // function test_distributeToHolders() public {
    //     assertEq(mpl.balanceOf(address(hal)), 0);
    //     assertEq(mpl.balanceOf(address(hue)), 0);

    //     mpl.transfer(address(hal), mpl.totalSupply() * 25 / 100);  // 25%
    //     mpl.transfer(address(hue), mpl.totalSupply() * 75 / 100);  // 75%

    //     assertEq(mpl.balanceOf(address(hal)), 2_500_000 ether);
    //     assertEq(mpl.balanceOf(address(hue)), 7_500_000 ether);

    //     assertEq(IERC20(USDC).balanceOf(address(treasury)), 0);

    //     IERC20(USDC).transfer(address(treasury), 100 * USD);

    //     assertEq(IERC20(USDC).balanceOf(address(treasury)), 100 * USD);
    //     assertEq(IERC20(USDC).balanceOf(address(mpl)),              0);

    //     assertTrue(!fakeGov.try_distributeToHolders());  // Non-governor can't distribute
    //     assertTrue(     gov.try_distributeToHolders());  // Governor can distribute

    //     assertEq(IERC20(USDC).balanceOf(address(treasury)),         0);  // Withdraws all funds
    //     assertEq(IERC20(USDC).balanceOf(address(mpl)),      100 * USD);  // Withdrawn to MPL address, where accounts can claim funds

    //     assertEq(IERC20(USDC).balanceOf(address(hal)), 0);  // Token holder hasn't claimed
    //     assertEq(IERC20(USDC).balanceOf(address(hue)), 0);  // Token holder hasn't claimed

    //     hal.withdrawFunds(address(mpl));
    //     hue.withdrawFunds(address(mpl));

    //     withinDiff(IERC20(USDC).balanceOf(address(hal)), 25 * USD, 1);  // Token holder has claimed proportional share of USDC
    //     withinDiff(IERC20(USDC).balanceOf(address(hue)), 75 * USD, 1);  // Token holder has claimed proportional share of USDC
    // }

    // function test_convertERC20() public {

    //     IMapleGlobals _globals = IMapleGlobals(address(globals));

    //     assertEq(IERC20(WBTC).balanceOf(address(treasury)), 0);
    //     assertEq(IERC20(WETH).balanceOf(address(treasury)), 0);
    //     assertEq(IERC20(DAI).balanceOf(address(treasury)),  0);

    //     IERC20(WBTC).transfer(address(treasury), 10 * BTC);
    //     IERC20(WETH).transfer(address(treasury), 10 ether);
    //     IERC20(DAI).transfer(address(treasury), 100 ether);

    //     assertEq(IERC20(WBTC).balanceOf(address(treasury)),  10 * BTC);
    //     assertEq(IERC20(WETH).balanceOf(address(treasury)),  10 ether);
    //     assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);
    //     assertEq(IERC20(USDC).balanceOf(address(treasury)),         0);

    //     uint256 expectedAmtFromWBTC = Util.calcMinAmount(_globals, WBTC, USDC,  10 * BTC);
    //     uint256 expectedAmtFromWETH = Util.calcMinAmount(_globals, WETH, USDC,  10 ether);
    //     uint256 expectedAmtFromDAI  = Util.calcMinAmount(_globals, DAI,  USDC, 100 ether);

    //     /*** Convert WBTC ***/
    //     assertTrue(!fakeGov.try_convertERC20(WBTC));  // Non-governor can't convert
    //     assertTrue(     gov.try_convertERC20(WBTC));  // Governor can convert

    //     assertEq(IERC20(WBTC).balanceOf(address(treasury)),         0);
    //     assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);

    //     withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromWBTC, 300);  // Less than 3% difference

    //     gov.distributeToHolders();  // Empty treasury balance of USDC

    //     /*** Convert WETH ***/
    //     assertTrue(!fakeGov.try_convertERC20(WETH));  // Non-governor can't convert
    //     assertTrue(     gov.try_convertERC20(WETH));  // Governor can convert

    //     assertEq(IERC20(WETH).balanceOf(address(treasury)),         0);
    //     assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);

    //     withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromWETH, 300);  // Less than 3% difference

    //     gov.distributeToHolders();  // Empty treasury balance of USDC

    //     /*** Convert DAI ***/
    //     assertTrue(!fakeGov.try_convertERC20(DAI));  // Non-governor can't convert
    //     assertTrue(     gov.try_convertERC20(DAI));  // Governor can convert

    //     assertEq(IERC20(WETH).balanceOf(address(treasury)), 0);
    //     assertEq(IERC20(DAI).balanceOf(address(treasury)),  0);

    //     withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromDAI, 300);  // Less than 3% difference
    // }

}
