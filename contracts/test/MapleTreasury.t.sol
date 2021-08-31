// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

// TODO: Test remain for the `convertERC20`, It would get added during integration tests.

import { DSTest } from "../../modules/ds-test/src/test.sol";
import { ERC20 }  from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { MapleTreasury } from "../MapleTreasury.sol";

import { Governor } from "./accounts/Governor.sol";

import { GlobalsMock, TokenMock } from "./mocks/Mocks.sol";

contract MapleTreasuryTest is DSTest {

    GlobalsMock   globals;
    Governor      governor; 
    Governor      notGovernor;
    MapleTreasury treasury;
    TokenMock     mpl;
    TokenMock     mockToken;

    address constant holder1     = address(1);
    address constant holder2     = address(2);
    address constant globalAdmin = address(3);

    function setUp() public {
        governor    = new Governor();
        notGovernor = new Governor();
        mpl         = new TokenMock("Maple",    "MPL");
        mockToken   = new TokenMock("MK token", "MK");
        globals     = new GlobalsMock(address(governor), address(mpl), address(globalAdmin));
        treasury    = new MapleTreasury(address(mpl), address(mockToken), address(1), address(globals));

        mpl.mint(address(this),       100);
        mockToken.mint(address(this), 100);
    }

    function test_setGlobals() public {
        assertEq(address(treasury.globals()), address(globals));

        assertTrue(!notGovernor.try_mapleTreasury_setGlobals(address(treasury), address(1)));  // Non-governor cannot set new globals
        assertTrue(    governor.try_mapleTreasury_setGlobals(address(treasury), address(1)));  // Governor can set new globals

        assertEq(address(treasury.globals()), address(1)); // Globals is updated
    }

    function test_reclaimERC20() public {
        assertEq(mockToken.balanceOf(address(treasury)), 0);

        mockToken.transfer(address(treasury), 100);

        assertEq(mockToken.balanceOf(address(treasury)), 100);
        assertEq(mockToken.balanceOf(address(governor)),  0);
        assertEq(treasury.globals(), address(globals));

        assertTrue(!notGovernor.try_mapleTreasury_reclaimERC20(address(treasury), address(mockToken), 40));  // Non-governor can't withdraw
        assertTrue(    governor.try_mapleTreasury_reclaimERC20(address(treasury), address(mockToken), 40));

        assertEq(mockToken.balanceOf(address(treasury)), 60);  // Can be distributed to MPL holders
        assertEq(mockToken.balanceOf(address(governor)),  40);  // Withdrawn to MapleDAO address for funding
    }

    function test_distributeToHolders() public {
        assertEq(mpl.balanceOf(address(holder1)), 0);
        assertEq(mpl.balanceOf(address(holder2)), 0);

        mpl.transfer(address(holder1), mpl.totalSupply() * 25 / 100);  // 25%
        mpl.transfer(address(holder2), mpl.totalSupply() * 75 / 100);  // 75%

        assertEq(mpl.balanceOf(address(holder1)), 25);
        assertEq(mpl.balanceOf(address(holder2)), 75);

        assertEq(mockToken.balanceOf(address(treasury)), 0);

        mockToken.transfer(address(treasury), 100);

        assertEq(mockToken.balanceOf(address(treasury)), 100);
        assertEq(mockToken.balanceOf(address(mpl)),      0);

        assertTrue(!notGovernor.try_mapleTreasury_distributeToHolders(address(treasury)));  // Non-governor can't distribute
        assertTrue(    governor.try_mapleTreasury_distributeToHolders(address(treasury)));  // Governor can distribute

        assertEq(mockToken.balanceOf(address(treasury)), 0);    // Withdraws all funds
        assertEq(mockToken.balanceOf(address(mpl)),      100);  // Withdrawn to MPL address, where accounts can claim funds
        assertEq(mockToken.balanceOf(address(holder1)),  0);    // Token holder hasn't claimed
        assertEq(mockToken.balanceOf(address(holder2)),  0);    // Token holder hasn't claimed
    }

}
