// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

// Why? Because the compiler doesn't like unconventional usage of the standard
// calldata bytes pointer `bytes calldata`. As such, we occupy 32 bits to
// indicate its start, however, its encoding is dependent on the schemas defined
// in the [`BBCDecoder`](src/types/BBCDecoder.sol) library.
type BytesCalldata is uint32;
