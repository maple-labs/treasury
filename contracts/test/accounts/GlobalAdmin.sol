// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IMapleGlobalsLike {
    function setProtocolPause(bool) external;
}

contract GlobalAdmin {

    /************************/
    /*** Direct Functions ***/
    /************************/
    function setProtocolPause(address globals, bool pause) external {
        IMapleGlobalsLike(globals).setProtocolPause(pause);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/
    function try_setProtocolPause(address globals, bool pause) external returns (bool ok) {
        string memory sig = "setProtocolPause(bool)";
        (ok,) = globals.call(abi.encodeWithSignature(sig, pause));
    }

}
