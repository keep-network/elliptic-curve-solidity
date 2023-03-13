// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * @author Witnet Foundation
 */
library EllipticCurve {

  // Pre-computed constant for 2 ** 255
  uint256 constant private U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  uint256 internal constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 internal constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 internal constant AA = 0;
  uint256 internal constant BB = 7;
  uint256 internal constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 internal constant NN = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @return q such that x*q = 1 (mod PP)
  function invMod(uint256 _x) internal pure returns (uint256) {
    unchecked {
    require(_x != 0 && _x != PP, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = PP;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (PP - mulmod(t, newT, PP)), PP));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
    }
  }

  /// @dev Modular exponentiation, b^e % PP.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param _base base
  /// @param _exp exponent
  /// @return r such that r = b**e (mod PP)
  function expMod(uint256 _base, uint256 _exp) internal pure returns (uint256) {
    require(PP!=0, "Modulus is zero");

    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;

    uint256 r = 1;
    uint256 bit = U255_MAX_PLUS_1;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, bit)))), PP)
        r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), PP)
        r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), PP)
        r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), PP)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  /// @param _x coordinate x
  /// @param _y coordinate y
  /// @param _z coordinate z
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z)
  internal pure returns (uint256, uint256)
  {
    uint256 zInv = invMod(_z);
    uint256 zInv2 = mulmod(zInv, zInv, PP);
    uint256 x2 = mulmod(_x, zInv2, PP);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, PP), PP);

    return (x2, y2);
  }

  /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
  /// @param _prefix parity byte (0x02 even, 0x03 odd)
  /// @param _x coordinate x
  /// @return y coordinate y
  function deriveY(
    uint8 _prefix,
    uint256 _x)
  internal pure returns (uint256)
  {
    require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, PP), PP), BB, PP);
    y2 = expMod(y2, (PP + 1) / 4);
    // uint256 cmp = yBit ^ y_ & 1;
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : PP - y2;

    return y;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and PP.
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint _x,
    uint _y)
  internal pure returns (bool)
  {
    if (0 == _x || _x >= PP || 0 == _y || _y >= PP) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, PP);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, PP), _x, PP);
    if (BB != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, BB, PP);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @return (x, -y)
  function ecInv(
    uint256 _x,
    uint256 _y)
  internal pure returns (uint256, uint256)
  {
    return (_x, (PP - _y) % PP);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2)
    internal pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;

    // Double if x1==x2 else add
    if (_x1==_x2) {
      // y1 = -y2 mod p
      if (addmod(_y1, _y2, PP) == 0) {
        return(0, 0);
      } else {
        // P1 = P2
        (x, y, z) = jacDouble(
          _x1,
          _y1,
          1);
      }
    } else {
      (x, y, z) = jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1);
    }
    // Get back to affine
    return toAffine(
      x,
      y,
      z);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2)
  internal pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(_x2, _y2);
    // P1-square
    return ecAdd(
      _x1,
      _y1,
      x,
      y);
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param _k scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y)
  internal pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      _k,
      _x,
      _y,
      1);
    // Get back to affine
    return toAffine(
      x1,
      y1,
      z1);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2). (non-allocating)
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _z1 coordinate z of P1
  /// @param _x2 coordinate x of square
  /// @param _y2 coordinate y of square
  /// @param _z2 coordinate z of square
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_x1==0 && _y1==0)
      return (_x2, _y2, _z2);
    if (_x2==0 && _y2==0)
      return (_x1, _y1, _z1);

    uint256 qx;
    uint256 qy;
    uint256 qz;

    assembly {
      // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
      // uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
      let zs := mload(0x40)
      // zs[0] = mulmod(_z1, _z1, PP);
      mstore(zs, mulmod(_z1, _z1, PP))
      // zs[1] = mulmod(_z1, zs[0], PP);
      mstore(add(zs, 0x20), mulmod(_z1, mload(zs), PP))
      // zs[2] = mulmod(_z2, _z2, PP);
      mstore(add(zs, 0x40), mulmod(_z2, _z2, PP))
      // zs[3] = mulmod(_z2, zs[2], PP);
      mstore(add(zs, 0x60), mulmod(_z2, mload(add(zs, 0x40)), PP))

      // u1, s1, u2, s2
      // zzs = [
      //   mulmod(_x1, zs[2], PP),
      //   mulmod(_y1, zs[3], PP),
      //   mulmod(_x2, zs[0], PP),
      //   mulmod(_y2, zs[1], PP)
      // ];
      mstore(add(zs, 0x80), mulmod(_x1, mload(add(zs, 0x40)), PP))
      mstore(add(zs, 0xa0), mulmod(_y1, mload(add(zs, 0x60)), PP))
      mstore(add(zs, 0xc0), mulmod(_x2, mload(zs), PP))
      mstore(add(zs, 0xe0), mulmod(_y2, mload(add(zs, 0x20)), PP))

      let zzs := add(zs, 0x80)
      // uint[4] memory hr;
      let hr := zs
      //h
      // hr[0] = addmod(zzs[2], PP - zzs[0], PP);
      mstore(hr, addmod(mload(add(zzs, 0x40)), sub(PP, mload(zzs)), PP))
      //r
      // hr[1] = addmod(zzs[3], PP - zzs[1], PP);
      mstore(add(hr, 0x20), addmod(mload(add(zzs, 0x60)), sub(PP, mload(add(zzs, 0x20))), PP))
      //h^2
      // hr[2] = mulmod(hr[0], hr[0], PP);
      mstore(add(hr, 0x40), mulmod(mload(hr), mload(hr), PP))
      // h^3
      // hr[3] = mulmod(hr[2], hr[0], PP);
      mstore(add(hr, 0x60), mulmod(mload(add(hr, 0x40)), mload(hr), PP))

      // qx = -h^3  -2u1h^2+r^2
      // uint256 qx = addmod(mulmod(hr[1], hr[1], PP), PP - hr[3], PP);
      qx := addmod(
        mulmod(mload(add(hr, 0x20)), mload(add(hr, 0x20)), PP),
        sub(PP, mload(add(hr, 0x60))),
        PP
      )
      // qx = addmod(qx, PP - mulmod(2, mulmod(zs[0], hr[2], PP), PP), PP);
      qx := addmod(
        qx,
        sub(PP, mulmod(2, mulmod(mload(zzs), mload(add(hr, 0x40)), PP), PP)),
        PP
      )
      // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
      // uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], PP), PP - qx, PP), PP);
      qy := mulmod(
        mload(add(hr, 0x20)),
        addmod(mulmod(mload(zzs), mload(add(hr, 0x40)), PP), sub(PP, qx), PP),
        PP
      )
      // qy = addmod(qy, PP - mulmod(zs[1], hr[3], PP), PP);
      qy := addmod(
        qy,
        sub(PP, mulmod(mload(add(zzs, 0x20)), mload(add(hr, 0x60)), PP)),
        PP
      )
      // qz = h*z1*z2
      // uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, PP), PP);
      qz := mulmod(mload(hr), mulmod(_z1, _z2, PP), PP)
    }

    return(qx, qy, qz);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);

    uint256 x;
    uint256 y;
    uint256 z;
    assembly {
      // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
      // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
      // x, y, z at this point represent the squares of _x, _y, _z
      x := mulmod(_x, _x, PP) //x1^2
      y := mulmod(_y, _y, PP) //y1^2
      z := mulmod(_z, _z, PP) //z1^2

      let s := mulmod(4, mulmod(_x, y, PP), PP)
      let m := mulmod(3, x, PP)

      // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
      // This allows to reduce the gas cost and stack footprint of the algorithm
      // qx
      x := addmod(mulmod(m, m, PP), sub(PP, addmod(s, s, PP)), PP)
      // qy = -8*y1^4 + M(S-T)
      y := addmod(mulmod(m, addmod(s, sub(PP, x), PP), PP), sub(PP, mulmod(8, mulmod(y, y, PP), PP)), PP)
      // qz = 2*y1*z1
      z := mulmod(2, mulmod(_y, _z, PP), PP)
    }

    return (x, y, z);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param _d scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z)
  internal pure returns (uint256, uint256, uint256)
  {
    // Early return in case that `_d == 0`
    if (_d == 0) {
      return (_x, _y, _z);
    }

    uint256 remaining = _d;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = jacAdd(
          qx,
          qy,
          qz,
          _x,
          _y,
          _z);
      }
      remaining = remaining / 2;
      (_x, _y, _z) = jacDouble(
        _x,
        _y,
        _z);
    }
    return (qx, qy, qz);
  }
}
