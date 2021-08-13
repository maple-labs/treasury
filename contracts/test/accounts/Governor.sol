// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

contract Governor {

    /*********************/
    /*** Try Functions ***/
    /*********************/
    function try_treasury_setGlobals(address target, address _globals) external returns (bool ok) {
        string memory sig = "setGlobals(address)";
        (ok,) = target.call(abi.encodeWithSignature(sig, _globals));
    }

    function try_treasury_reclaimERC20(address treasury, address asset, uint256 amount) external returns (bool ok) {
        string memory sig = "reclaimERC20(address,uint256)";
        (ok,) = treasury.call(abi.encodeWithSignature(sig, asset, amount));
    }

    function try_treasury_distributeToHolders(address treasury) external returns (bool ok) {
        string memory sig = "distributeToHolders()";
        (ok,) = treasury.call(abi.encodeWithSignature(sig));
    }

}
