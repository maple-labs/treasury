// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { ERC20 }  from "../../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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

    function updateFundsReceived() external {}

}
