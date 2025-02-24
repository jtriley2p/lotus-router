// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";

type UniV2Pair is address;

using { swap } for UniV2Pair global;

// keccak256("swap(uint256,uint256,address,bytes)")
uint256 constant swapSelector = 0x022c0d9f00000000000000000000000000000000000000000000000000000000;

// ## Execute Uniswap V2 Swap
//
// ## Parameters
//
// - pair: The Uniswap V2 pair address.
// - amount0Out: The expected output amount for token 0.
// - amount1Out: The expected output amount for token 1.
// - to: The receiver of the swap output.
// - data: The arbitrary calldata for UniV2 callbacks, if any.
//
// ## Returns
//
// - success: returns True if the swap succeeded.
//
// ## Notes
//
// - If swapping across multiple pairs, `to` will be the next pair in the chain.
// - This is memory safe, as we do not interfere with allocated memory and we
//   allow it to be freed after this function ends.
//
// ## Procedures
//
// 01. Load the free memory pointer.
// 02. Load the `data` length as a 32 bit integer.
// 03. Increment the `data` pointer to the beginning of the bytes.
// 04. Store the `swapSelector`.
// 05. Store the `amount0Out` argument.
// 06. Store the `amount1Out` argument.
// 07. Store the `to` argument.
// 08. Store the `data` offset, relative to the slot after the selector.
// 09. Store the `dataLen`.
// 10. Copy the data from calldata to memory.
// 11. Call the `pair` contract, returning `success` to the caller of this
//    function.
function swap(
    UniV2Pair pair,
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    BytesCalldata data
) returns (bool success) {
    assembly ("memory-safe") {
        let fmp := mload(0x40)

        let dataLen := shr(0xe0, calldataload(data))

        data := add(data, 0x04)

        mstore(add(0x00, fmp), swapSelector)

        mstore(add(0x04, fmp), amount0Out)

        mstore(add(0x24, fmp), amount1Out)

        mstore(add(0x44, fmp), to)

        mstore(add(0x64, fmp), 0x80)

        mstore(add(0x84, fmp), dataLen)

        calldatacopy(add(0xa4, fmp), data, dataLen)

        success := call(gas(), pair, 0x00, fmp, add(0xc4, dataLen), 0x00, 0x00)
    }
}
