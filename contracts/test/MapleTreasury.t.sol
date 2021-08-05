// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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

contract MockToken is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

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
    MockToken                  mpl;
    MockToken                 mock;
    Hevm                      hevm;
    Holder                     holder1;
    Holder                     holder2;
    GlobalAdmin    realGlobalAdmin;

    constructor() public {
        hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))); 
    }

    function setUp() public {

        realGlobalAdmin = new GlobalAdmin();
        realGov         = new Governor();
        fakeGov         = new Governor();
        mpl             = new MockToken("Maple",    "MPL");
        mock            = new MockToken("MK token", "MK");
        globals         = new MapleGlobals(address(realGov), address(mpl), address(realGlobalAdmin));
        treasury        = new MapleTreasury(address(mpl), address(mock), address(1), address(globals));
        holder1         = new Holder();
        holder2         = new Holder();

        mpl.mint(address(this),  100);
        mock.mint(address(this), 100);
    }

    function test_setGlobals() public {
        IMapleGlobals globals2 = fakeGov.createGlobals(address(mpl));  // Create upgraded MapleGlobals
        assertEq(address(treasury.globals()), address(globals));

        assertTrue(!fakeGov.try_treasury_setGlobals(address(treasury), address(globals2)));  // Non-governor cannot set new globals

        globals2 = realGov.createGlobals(address(mpl)); // Create upgraded MapleGlobals

        assertTrue(realGov.try_treasury_setGlobals(address(treasury), address(globals2))); // Governor can set new globals
        assertEq(address(treasury.globals()), address(globals2)); // Globals is updated
    }

    function test_reclaimERC20() public {
        assertEq(mock.balanceOf(address(treasury)), 0);

        mock.transfer(address(treasury), 100);

        assertEq(mock.balanceOf(address(treasury)), 100);
        assertEq(mock.balanceOf(address(realGov)),  0);
        assertEq(treasury.globals(), address(globals));

        assertTrue(!fakeGov.try_treasury_reclaimERC20(address(treasury), address(mock), 40));  // Non-governor can't withdraw
        assertTrue( realGov.try_treasury_reclaimERC20(address(treasury), address(mock), 40));

        assertEq(mock.balanceOf(address(treasury)), 60);  // Can be distributed to MPL holders
        assertEq(mock.balanceOf(address(realGov)),  40);  // Withdrawn to MapleDAO address for funding
    }

    function test_distributeToHolders() public {
        assertEq(mpl.balanceOf(address(holder1)), 0);
        assertEq(mpl.balanceOf(address(holder2)), 0);

        mpl.transfer(address(holder1), mpl.totalSupply() * 25 / 100);  // 25%
        mpl.transfer(address(holder2), mpl.totalSupply() * 75 / 100);  // 75%

        assertEq(mpl.balanceOf(address(holder1)), 25);
        assertEq(mpl.balanceOf(address(holder2)), 75);

        assertEq(mock.balanceOf(address(treasury)), 0);

        mock.transfer(address(treasury), 100);

        assertEq(mock.balanceOf(address(treasury)), 100);
        assertEq(mock.balanceOf(address(mpl)),      0);

        assertTrue(!fakeGov.try_treasury_distributeToHolders(address(treasury)));  // Non-governor can't distribute
        assertTrue( realGov.try_treasury_distributeToHolders(address(treasury)));  // Governor can distribute

        assertEq(mock.balanceOf(address(treasury)), 0);  // Withdraws all funds
        assertEq(mock.balanceOf(address(mpl)),      100);  // Withdrawn to MPL address, where accounts can claim funds
        assertEq(mock.balanceOf(address(holder1)),  0);  // Token holder hasn't claimed
        assertEq(mock.balanceOf(address(holder2)),  0);  // Token holder hasn't claimed
    }

    // TODO: Test remain for the `converERC20`, It would get added during integration tests.

}

