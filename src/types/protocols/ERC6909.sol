// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

type ERC6909 is address;

using { transfer, transferFrom } for ERC6909 global;

uint256 constant transferSelector =
    0x095bcdb600000000000000000000000000000000000000000000000000000000;
uint256 constant transferFromSelector =
    0xfe99049a00000000000000000000000000000000000000000000000000000000;

// ## Execute ERC6909 transfer
//
// ### Parameters
//
// - token: The ERC6909 address.
// - receiver: The transfer receiver address.
// - tokenId: The ID of the token to transfer.
// - amount: The transfer amount.
//
// ### Returns
//
// - success: returns True if the transfer succeeded
//
// ### Notes
//
// Since the calldata of this is small, we allocate the memory for it in the
// scratchspace normally used by Solidity for keccak hashing. This reduces
// overall memory allocations. However, it's worth noting that doing this
// occupies the first 100 bytes, which overwrites the free memory pointer and
// the first four bytes of the zero slot `0x60`. So we overwrite these upper
// bytes at the end to ensure the free memory pointer and zero slot are correct.
//
// ### Procedures
//
// 01. Load the free memory pointer.
// 02. Store the `transferSelector`.
// 03. Store the `receiver`.
// 04. Store the `tokenId`.
// 05. Store the `amount`.
// 06. Call the `token` contract, caching the `success` boolean.
// 07. Check that the return value is true (0x01).
// 08. Restore the free memory pointer.
// 09. Restore the zero slot.
function transfer(
    ERC6909 multitoken,
    address receiver,
    uint256 tokenId,
    uint256 amount
) returns (bool success) {
    assembly ("memory-safe") {
        let fmp := mload(0x40)

        mstore(0x00, transferSelector)

        mstore(0x04, receiver)

        mstore(0x24, tokenId)

        mstore(0x44, amount)

        success := call(gas(), multitoken, 0x00, 0x00, 0x64, 0x00, 0x20)

        success := and(success, eq(0x01, mload(0x00)))

        mstore(0x40, fmp)

        mstore(0x60, 0x00)
    }
}

// ## Execute ERC6909 transfer
//
// ### Parameters
//
// - token: The ERC6909 address.
// - receiver: The transfer receiver address.
// - tokenId: The ID of the token to transfer.
// - amount: The transfer amount.
//
// ### Returns
//
// - success: returns True if the transfer succeeded
//
// ### Notes
//
// We store data at the end of allocated memory. Generally, memory is not
// allocated (as in the free memory pointer is updated), but in the interest of
// keeping this straight forward for modifications, we use the free memory
// pointer to start allocating memory.
//
// Note that we do not update the free memory pointer, as this allows solidity
// to overwrite this memory, saving space. Again, this is likely of little to
// no consequnece in the Lotus Router, but modifications may.
//
// ### Procedures
//
// 01. Load the free memory pointer.
// 02. Store the `transferFrom`.
// 03. Store the `sender`.
// 04. Store the `receiver`.
// 05. Store the `tokenId`.
// 06. Store the `amount`.
// 07. Call the `token` contract, caching the `success` boolean.
// 08. Check that the return value is true (0x01).
function transferFrom(
    ERC6909 multitoken,
    address sender,
    address receiver,
    uint256 tokenId,
    uint256 amount
) returns (bool success) {
    assembly ("memory-safe") {
        let fmp := mload(0x40)

        mstore(add(fmp, 0x00), transferFromSelector)

        mstore(add(fmp, 0x04), sender)

        mstore(add(fmp, 0x24), receiver)

        mstore(add(fmp, 0x44), tokenId)

        mstore(add(fmp, 0x64), amount)

        success := call(gas(), multitoken, 0x00, fmp, 0x84, fmp, 0x20)

        success := and(success, eq(0x01, mload(fmp)))
    }
}
