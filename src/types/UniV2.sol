// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

type UniV2Pair is address;

using {swap} for UniV2Pair global;

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
// 1. Load the free memory pointer.
// 2. Store the `swapSelector`.
// 3. Store the `amount0Out` argument.
// 4. Store the `amount1Out` argument.
// 5. Store the `to` argument.
// 6. Store the `data.offset`, relative to the slot after the selector.
// 7. Store the `data.length`.
// 8. Copy the data from calldata to memory.
// 9. Call the `pair` contract, returning `success` to the caller of this
//    function.
function swap(UniV2Pair pair, uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data)
    returns (bool success)
{
    assembly ("memory-safe") {
        let ptr := mload(0x40)

        mstore(add(0x00, ptr), swapSelector)

        mstore(add(0x04, ptr), amount0Out)

        mstore(add(0x24, ptr), amount1Out)

        mstore(add(0x44, ptr), to)

        mstore(add(0x64, ptr), 0x80)

        mstore(add(0x84, ptr), data.length)

        calldatacopy(add(0xa4, ptr), data.offset, data.length)

        success := call(gas(), pair, 0x00, ptr, add(0xc4, data.length), 0x00, 0x00)
    }
}
