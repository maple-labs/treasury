// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IERC20 }        from "../../../modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IMapleGlobals } from "../../../modules/globals/contracts/interfaces/IMapleGlobals.sol";
import { MapleGlobals }  from "../../../modules/globals/contracts/MapleGlobals.sol";

import { IMapleTreasury }  from "../../interfaces/IMapleTreasury.sol";

contract Governor {

    /************************/
    /*** Direct Functions ***/
    /************************/
    function setPriceOracle(address globals, address asset, address oracle) external {
        IMapleGlobals(globals).setPriceOracle(asset, oracle); 
    }

    function distributeToHolders(IMapleTreasury treasury) external {
        treasury.distributeToHolders(); 
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/
    function try_treasury_setGlobals(address target, address _globals) external returns (bool ok) {
        string memory sig = "setGlobals(address)";
        (ok,) = address(target).call(abi.encodeWithSignature(sig, _globals));
    }

    function try_treasury_reclaimERC20(address treasury, address asset, uint256 amount) external returns (bool ok) {
        string memory sig = "reclaimERC20(address,uint256)";
        (ok,) = address(treasury).call(abi.encodeWithSignature(sig, asset, amount));
    }

    function try_treasury_distributeToHolders(address treasury) external returns (bool ok) {
        string memory sig = "distributeToHolders()";
        (ok,) = address(treasury).call(abi.encodeWithSignature(sig));
    }

    function try_treasury_convertERC20(address treasury, address asset) external returns (bool ok) {
        string memory sig = "convertERC20(address)";
        (ok,) = address(treasury).call(abi.encodeWithSignature(sig, asset));
    }

    function createGlobals(address mpl) external returns (MapleGlobals globals) {
        return MapleGlobals(new MapleGlobals(address(this), mpl, address(1)));
    }

}
