// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IMapleTreasury } from "../../interfaces/IMapleTreasury.sol";

contract Governor {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function mapleTreasury_setGlobals(address treasury, address globals) external {
        IMapleTreasury(treasury).setGlobals(globals);
    }

    function mapleTreasury_reclaimERC20(address treasury, address asset, uint256 amount) external {
        IMapleTreasury(treasury).reclaimERC20(asset, amount);
    }

    function mapleTreasury_distributeToHolders(address treasury) external {
        IMapleTreasury(treasury).distributeToHolders();
    }

    function mapleTreasury_convertERC20(address treasury, address asset) external {
        IMapleTreasury(treasury).convertERC20(asset);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_mapleTreasury_setGlobals(address treasury, address globals) external returns (bool ok) {
        (ok,) = treasury.call(abi.encodeWithSelector(IMapleTreasury.setGlobals.selector, globals));
    }

    function try_mapleTreasury_reclaimERC20(address treasury, address asset, uint256 amount) external returns (bool ok) {
        (ok,) = treasury.call(abi.encodeWithSelector(IMapleTreasury.reclaimERC20.selector, asset, amount));
    }

    function try_mapleTreasury_distributeToHolders(address treasury) external returns (bool ok) {
        (ok,) = treasury.call(abi.encodeWithSelector(IMapleTreasury.distributeToHolders.selector));
    }

    function try_mapleTreasury_convertERC20(address treasury, address asset) external returns (bool ok) {
        (ok,) = treasury.call(abi.encodeWithSelector(IMapleTreasury.convertERC20.selector, asset));
    }

}
