// SPDX-License-Identifier: MIT

pragma solidity >=0.5.3 <0.7.0;

import {EllipticCurve as ec} from "./EllipticCurve.sol";
import {FastEcMul as fec} from "./FastEcMul.sol";

library Schnorr {

    function verify(bytes memory sig, bytes32 pk, bytes32 m) internal pure returns (bool, string memory) {
        require(sig.length == 64, "invalid signature length");
        uint256 py = ec.deriveY(uint8(0x02), uint256(pk));
        if (!ec.isOnCurve(uint256(pk), py)) return (false, "pk not on curve");
        uint256 r;
        uint256 s;
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
        }
        if (r >= ec.PP) return (false, "invalid r");
        if (s >= ec.NN) return (false, "invalid s");

        uint256 e = uint256(hash(abi.encodePacked(r, pk, m))) % ec.NN;

        uint256 negE = ec.NN - e;

        int256[4] memory se;
        (se[0], se[1]) = fec.decomposeScalar(s);
        (se[2], se[3]) = fec.decomposeScalar(negE);

        uint256[4] memory gp = [ec.GX, ec.GY, uint256(pk), py];

        (uint256 Rx, uint256 Ry) = fec.ecSimMul(se, gp);

        if (!ec.isOnCurve(Rx, Ry)) return (false, "point R infinite"); // XXX: audit infinity handling
        if (Ry % 2 == 1) return (false, "R.y not even");

        if (Rx != r) return (false, "R and r mismatch");
        return (true, "");
    }

    function hash(bytes memory data) internal pure returns (bytes32) {
        string memory tag = "BIP0340/challenge";
        bytes32 htag = sha256(abi.encodePacked(tag));
        return sha256(abi.encodePacked(htag, htag, data));
    }
}