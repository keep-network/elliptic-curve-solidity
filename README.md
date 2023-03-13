# elliptic-curve-solidity [![npm version](https://badge.fury.io/js/elliptic-curve-solidity.svg)](https://badge.fury.io/js/elliptic-curve-solidity) [![TravisCI](https://travis-ci.com/witnet/elliptic-curve-solidity.svg?branch=master)](https://travis-ci.com/witnet/elliptic-curve-solidity) [![Coverage Status](https://coveralls.io/repos/github/witnet/elliptic-curve-solidity/badge.svg?branch=master)](https://coveralls.io/github/witnet/elliptic-curve-solidity?branch=master)

`elliptic-curve-solidity` is an open source implementation of Elliptic Curve arithmetic operations written in Solidity.

_DISCLAIMER: This is experimental software. **Use it at your own risk**!_

The solidity contracts have been specialised in order to optimise gas costs with secp256k1.

`elliptic-curve-solidity` has been designed as a library with **only pure functions** aiming at decreasing gas consumption as much as possible. Additionally, gas consumption comparison can be found in the benchmark section. This library **does not check whether the points passed as arguments to the library belong to the curve**. However, the library exposes a method called *`isOnCurve`* that can be utilized before using the library functions.

It contains 2 solidity libraries:

1. `EllipticCurve.sol`: provides main elliptic curve operations in affine and Jacobian coordinates.
2. `FastEcMul.sol`: provides a fast elliptic curve multiplication by using scalar decomposition and wNAF scalar representation.

`EllipticCurve` library provides functions for:

- Modular
  - inverse
  - exponentiation
- Jacobian coordinates
  - addition
  - double
  - multiplication
- Affine coordinates
  - inverse
  - addition
  - subtraction
  - multiplication
- Auxiliary
  - conversion to affine coordinates
  - derive coordinate Y from compressed EC point
  - check if EC point is on curve

`FastEcMul` library provides support for:

- Scalar decomposition
- Simultaneous multiplication (computes 2 EC multiplications using wNAF scalar representation)

## Supported curves

This version of the `elliptic-curve-solidity` contract supports only `secp256k1`.

## Usage

`EllipticCurve.sol` library can be used directly by importing it.

The cost of a simultaneous multiplication (using wNAF) consumes around 35% of the gas required by 2 EC multiplications.

## Benchmark

Gas consumption and USD price estimation with a gas price of 100 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
before:

·----------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.6.12+commit.27d51765  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6718946 gas  │
·········································|···························|·············|·····························
|  Methods                                                                                                      │
··················|······················|·············|·············|·············|··············|··············
|  Contract       ·  Method              ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _decomposeScalar    ·      64717  ·      65399  ·      65000  ·          54  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _deriveY            ·          -  ·          -  ·      55545  ·           2  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecAdd              ·      24305  ·      55060  ·      52243  ·          80  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecInv              ·          -  ·          -  ·      23074  ·           1  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecMul              ·      25199  ·     622862  ·     355019  ·          94  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSimMul           ·      76465  ·     488165  ·     133060  ·          47  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSub              ·      50194  ·      55327  ·      53695  ·          38  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _invMod             ·      22333  ·      49255  ·      40222  ·           6  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _isOnCurve          ·      23400  ·      23605  ·      23474  ·          12  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _toAffine           ·          -  ·          -  ·      50145  ·           2  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  Deployments                           ·                                         ·  % of limit  ·             │
·········································|·············|·············|·············|··············|··············
|  EcGasHelper                           ·          -  ·          -  ·    1531464  ·      22.8 %  ·          -  │
·----------------------------------------|-------------|-------------|-------------|--------------|-------------·

after:

·----------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.6.12+commit.27d51765  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6718946 gas  │
·········································|···························|·············|·····························
|  Methods                                                                                                      │
··················|······················|·············|·············|·············|··············|··············
|  Contract       ·  Method              ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _decomposeScalar    ·      64604  ·      65274  ·      64878  ·          54  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _deriveY            ·          -  ·          -  ·      56934  ·           2  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecAdd              ·      24280  ·      49799  ·      47440  ·          80  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecInv              ·          -  ·          -  ·      23041  ·           1  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecMul              ·      24722  ·     385816  ·     226941  ·          94  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSimMul           ·      66872  ·     364698  ·     107979  ·          47  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSub              ·      45702  ·      50023  ·      48649  ·          38  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _invMod             ·      22308  ·      45030  ·      37406  ·           6  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _isOnCurve          ·      23384  ·      23499  ·      23429  ·          12  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _toAffine           ·          -  ·          -  ·      45937  ·           2  ·          -  │
··················|······················|·············|·············|·············|··············|··············
|  Deployments                           ·                                         ·  % of limit  ·             │
·········································|·············|·············|·············|··············|··············
|  EcGasHelper                           ·          -  ·          -  ·    1510390  ·      22.5 %  ·          -  │
·----------------------------------------|-------------|-------------|-------------|--------------|-------------·
```

## Acknowledgements

Some functions of the contract are based on:

- [Comparatively Study of ECC and Jacobian Elliptic Curve Cryptography](https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf) by Anagha P. Zele and Avinash P. Wadhe
- [`Numerology`](https://github.com/nucypher/numerology) by NuCypher
- [`solidity-arithmetic`](https://github.com/gnosis/solidity-arithmetic) by Gnosis
- [`ecsol`](https://github.com/jbaylina/ecsol) written by Jordi Baylina
- [`standard contracts`](https://github.com/androlo/standard-contracts) written by Andreas Olofsson

## License

`elliptic-curve-solidity` is published under the [MIT license][license].

[license]: https://github.com/witnet/elliptic-curve-solidity/blob/master/LICENSE
