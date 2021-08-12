// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { DSTest }        from "../../modules/ds-test/src/test.sol";
import { ERC20 }         from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { Governor }       from "./accounts/Governor.sol";

import { MapleTreasury }  from "../MapleTreasury.sol";

contract GlobalsMock {

    address public governor;
    address public mpl;
    address public globalAdmin;

    constructor(address _governor, address _mpl, address _globalAdmin) public {
        governor    = _governor;
        mpl         = _mpl;
        globalAdmin = _globalAdmin;
    }

}

contract TokenMock is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function updateFundsReceived() external { }

}

contract MapleTreasuryTest is DSTest {

    Governor      realGov; 
    Governor      fakeGov;
    MapleTreasury treasury;
    GlobalsMock   globals;
    TokenMock     mpl;
    TokenMock     mockToken;

    address constant holder1     = address(1);
    address constant holder2     = address(2);
    address constant globalAdmin = address(3);

    function setUp() public {
        realGov         = new Governor();
        fakeGov         = new Governor();
        mpl             = new TokenMock("Maple",    "MPL");
        mockToken       = new TokenMock("MK token", "MK");
        globals         = new GlobalsMock(address(realGov), address(mpl), address(globalAdmin));
        treasury        = new MapleTreasury(address(mpl), address(mockToken), address(1), address(globals));

        mpl.mint(address(this),       100);
        mockToken.mint(address(this), 100);
    }

    function test_setGlobals() public {
        assertEq(address(treasury.globals()), address(globals));

        assertTrue(!fakeGov.try_treasury_setGlobals(address(treasury), address(1)));  // Non-governor cannot set new globals
        assertTrue( realGov.try_treasury_setGlobals(address(treasury), address(1))); // Governor can set new globals

        assertEq(address(treasury.globals()), address(1)); // Globals is updated
    }

    function test_reclaimERC20() public {
        assertEq(mockToken.balanceOf(address(treasury)), 0);

        mockToken.transfer(address(treasury), 100);

        assertEq(mockToken.balanceOf(address(treasury)), 100);
        assertEq(mockToken.balanceOf(address(realGov)),  0);
        assertEq(treasury.globals(), address(globals));

        assertTrue(!fakeGov.try_treasury_reclaimERC20(address(treasury), address(mockToken), 40));  // Non-governor can't withdraw
        assertTrue( realGov.try_treasury_reclaimERC20(address(treasury), address(mockToken), 40));

        assertEq(mockToken.balanceOf(address(treasury)), 60);  // Can be distributed to MPL holders
        assertEq(mockToken.balanceOf(address(realGov)),  40);  // Withdrawn to MapleDAO address for funding
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

        assertTrue(!fakeGov.try_treasury_distributeToHolders(address(treasury)));  // Non-governor can't distribute
        assertTrue( realGov.try_treasury_distributeToHolders(address(treasury)));  // Governor can distribute

        assertEq(mockToken.balanceOf(address(treasury)), 0);    // Withdraws all funds
        assertEq(mockToken.balanceOf(address(mpl)),      100);  // Withdrawn to MPL address, where accounts can claim funds
        assertEq(mockToken.balanceOf(address(holder1)),  0);    // Token holder hasn't claimed
        assertEq(mockToken.balanceOf(address(holder2)),  0);    // Token holder hasn't claimed
    }

    // TODO: Test remain for the `converERC20`, It would get added during integration tests.

}

