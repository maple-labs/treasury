pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Treasury.sol";

contract TreasuryTest is DSTest {
    Treasury treasury;

    function setUp() public {
        treasury = new Treasury();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
