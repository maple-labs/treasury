// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { IERC20 }        from "../../modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC20 }         from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Util }          from "../../modules/util/contracts/Util.sol";
import { IMapleGlobals } from "../../modules/globals/contracts/interfaces/IMapleGlobals.sol";
import { MapleGlobals }  from "../../modules/globals/contracts/MapleGlobals.sol";
import { DSTest }        from "../../modules/ds-test/src/test.sol";

import { Governor }       from "./accounts/Governor.sol";
import { GlobalAdmin }    from "./accounts/GlobalAdmin.sol";
import { MapleTreasury }  from "../MapleTreasury.sol";
import { IMapleTreasury } from "../interfaces/IMapleTreasury.sol";

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

interface Hevm {

    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;

}

interface IBasicFDT {
    /**
        @dev Withdraws all available funds for the calling FDT holder.
     */
    function withdrawFunds() external;
}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset) external view returns (uint256);

}

contract Holder {

    function withdrawFunds(address token) external {
        IBasicFDT(token).withdrawFunds();
    }

}

contract MapleTreasuryTest is DSTest {

    Governor               realGov; 
    Governor               fakeGov;
    MapleTreasury         treasury;
    MapleGlobals           globals;
    GlobalAdmin    realGlobalAdmin;
    MapleToken                 mpl;
    Hevm                      hevm;
    Holder                     hal;
    Holder                     hue;

    constructor() public { hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))); }

    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  // Uniswap V2 Router
    address constant USDC                 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI                  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH                 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC                 = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant wethOracle           = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant wbtcOracle           = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant usdcOracle           = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 constant USD                  = 10 ** 6;  // USDC precision decimals
    uint256 constant BTC                  = 10 ** 8;  // WBTC precision decimals
    uint256 constant WAD                  = 10 ** 18;
    uint256 constant RAY                  = 10 ** 27;


    function setUp() public {

        realGlobalAdmin = new GlobalAdmin();
        realGov         = new Governor();
        fakeGov         = new Governor();
        mpl             = new MapleToken("Maple", "MPL");
        globals         = new MapleGlobals(address(realGov), address(mpl), address(realGlobalAdmin));
        treasury        = new MapleTreasury(address(mpl), USDC, UNISWAP_V2_ROUTER_02, address(globals));
        hal             = new Holder();
        hue             = new Holder();
        
        mint(WBTC, address(this),  10 * BTC, 0);
        mint(WETH, address(this),  10 ether, 3);
        mint(DAI,  address(this), 100 ether, 2);
        mint(USDC, address(this), 100 * USD, 9);

        mpl.mint(address(this), 10000000 * WAD);

        realGov.setPriceOracle(address(globals), WETH, wethOracle);
        realGov.setPriceOracle(address(globals), WBTC, wbtcOracle);
        realGov.setPriceOracle(address(globals), DAI,  usdcOracle);
    }

    function test_setGlobals() public {
        IMapleGlobals globals2 = fakeGov.createGlobals(address(mpl));               // Create upgraded MapleGlobals
        assertEq(address(treasury.globals()), address(globals));

        assertTrue(!fakeGov.try_setGlobals(address(treasury), address(globals2)));  // Non-governor cannot set new globals

        globals2 = realGov.createGlobals(address(mpl));                             // Create upgraded MapleGlobals

        assertTrue(realGov.try_setGlobals(address(treasury), address(globals2)));   // Governor can set new globals
        assertEq(address(treasury.globals()), address(globals2));                   // Globals is updated
    }

    function test_withdrawFunds() public {
        assertEq(IERC20(USDC).balanceOf(address(treasury)), 0);

        IERC20(USDC).transfer(address(treasury), 100 * USD);

        assertEq(IERC20(USDC).balanceOf(address(treasury)), 100 * USD);
        assertEq(IERC20(USDC).balanceOf(address(realGov)),          0);
        assertEq(treasury.globals(), address(globals));

        assertTrue(!fakeGov.try_reclaimERC20_treasury(address(treasury), USDC, 40 * USD));  // Non-governor can't withdraw
        assertTrue( realGov.try_reclaimERC20_treasury(address(treasury), USDC, 40 * USD));

        assertEq(IERC20(USDC).balanceOf(address(treasury)), 60 * USD);  // Can be distributed to MPL holders
        assertEq(IERC20(USDC).balanceOf(address(realGov)),  40 * USD);  // Withdrawn to MapleDAO address for funding
    }

    function test_distributeToHolders() public {
        assertEq(mpl.balanceOf(address(hal)), 0);
        assertEq(mpl.balanceOf(address(hue)), 0);

        mpl.transfer(address(hal), mpl.totalSupply() * 25 / 100);  // 25%
        mpl.transfer(address(hue), mpl.totalSupply() * 75 / 100);  // 75%

        assertEq(mpl.balanceOf(address(hal)), 2_500_000 ether);
        assertEq(mpl.balanceOf(address(hue)), 7_500_000 ether);

        assertEq(IERC20(USDC).balanceOf(address(treasury)), 0);

        IERC20(USDC).transfer(address(treasury), 100 * USD);

        assertEq(IERC20(USDC).balanceOf(address(treasury)), 100 * USD);
        assertEq(IERC20(USDC).balanceOf(address(mpl)),              0);

        assertTrue(!fakeGov.try_distributeToHolders(address(treasury)));  // Non-governor can't distribute
        assertTrue( realGov.try_distributeToHolders(address(treasury)));  // Governor can distribute

        assertEq(IERC20(USDC).balanceOf(address(treasury)),         0);  // Withdraws all funds
        assertEq(IERC20(USDC).balanceOf(address(mpl)),      100 * USD);  // Withdrawn to MPL address, where accounts can claim funds

        assertEq(IERC20(USDC).balanceOf(address(hal)), 0);  // Token holder hasn't claimed
        assertEq(IERC20(USDC).balanceOf(address(hue)), 0);  // Token holder hasn't claimed
    }

    function test_convertERC20() public {

        IMapleGlobalsLike _globals = IMapleGlobalsLike(address(globals));

        assertEq(IERC20(WBTC).balanceOf(address(treasury)), 0);
        assertEq(IERC20(WETH).balanceOf(address(treasury)), 0);
        assertEq(IERC20(DAI).balanceOf(address(treasury)),  0);

        IERC20(WBTC).transfer(address(treasury), 10 * BTC);
        IERC20(WETH).transfer(address(treasury), 10 ether);
        IERC20(DAI).transfer(address(treasury), 100 ether);

        assertEq(IERC20(WBTC).balanceOf(address(treasury)),  10 * BTC);
        assertEq(IERC20(WETH).balanceOf(address(treasury)),  10 ether);
        assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);
        assertEq(IERC20(USDC).balanceOf(address(treasury)),         0);

        uint256 expectedAmtFromWBTC = Util.calcMinAmount(_globals, WBTC, USDC,  10 * BTC);
        uint256 expectedAmtFromWETH = Util.calcMinAmount(_globals, WETH, USDC,  10 ether);
        uint256 expectedAmtFromDAI  = Util.calcMinAmount(_globals, DAI,  USDC, 100 ether);

        /*** Convert WBTC ***/
        assertTrue(!fakeGov.try_convertERC20(address(treasury), WBTC));  // Non-governor can't convert
        assertTrue( realGov.try_convertERC20(address(treasury), WBTC));  // Governor can convert

        assertEq(IERC20(WBTC).balanceOf(address(treasury)),         0);
        assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);

        withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromWBTC, 300);  // Less than 3% difference

        realGov.distributeToHolders(IMapleTreasury(address(treasury)));  // Empty treasury balance of USDC

        /*** Convert WETH ***/
        assertTrue(!fakeGov.try_convertERC20(address(treasury), WETH));  // Non-governor can't convert
        assertTrue( realGov.try_convertERC20(address(treasury), WETH));  // Governor can convert

        assertEq(IERC20(WETH).balanceOf(address(treasury)),         0);
        assertEq(IERC20(DAI).balanceOf(address(treasury)),  100 ether);

        withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromWETH, 300);  // Less than 3% difference

        realGov.distributeToHolders(IMapleTreasury(address(treasury)));  // Empty treasury balance of USDC

        /*** Convert DAI ***/
        assertTrue(!fakeGov.try_convertERC20(address(treasury), DAI));  // Non-governor can't convert
        assertTrue( realGov.try_convertERC20(address(treasury), DAI));  // Governor can convert

        assertEq(IERC20(WETH).balanceOf(address(treasury)), 0);
        assertEq(IERC20(DAI).balanceOf(address(treasury)),  0);

        withinPercentage(IERC20(USDC).balanceOf(address(treasury)), expectedAmtFromDAI, 300);  // Less than 3% difference
    }

     // Manipulate mainnet ERC20 balance
    function mint(address addr, address account, uint256 amt, uint256 slot) public {
        uint256 bal = IERC20(addr).balanceOf(account);

        hevm.store(
            addr,
            keccak256(abi.encode(account, slot)), // Mint tokens
            bytes32(bal + amt)
        );

        assertEq(IERC20(addr).balanceOf(account), bal + amt, "Balance slot is wrong");  // Assert new balance
    }

    // Verify equality within accuracy percentage (basis points)
    function withinPercentage(uint256 val0, uint256 val1, uint256 percentage) public {
        uint256 diff = getDiff(val0, val1);
        if (diff == 0) return;

        uint256 denominator = val0 == 0 ? val1 : val0;
        bool check = ((diff * RAY) / denominator) < percentage * RAY / 10_000;

        if (check) return;

        emit log_named_uint("Error: approx a == b not satisfied, accuracy digits ", percentage);
        emit log_named_uint("  Expected", val0);
        emit log_named_uint("    Actual", val1);
        fail();
    }

    function getDiff(uint256 val0, uint256 val1) internal pure returns (uint256 diff) {
        diff = val0 > val1 ? val0 - val1 : val1 - val0;
    }
}
