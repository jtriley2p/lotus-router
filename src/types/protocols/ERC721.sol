// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

type ERC721 is address;

using { transferFrom } for ERC721 global;

uint256 constant transferFromSelector =
    0x23b872dd00000000000000000000000000000000000000000000000000000000;

// ## Execute ERC721 transfer
//
// ### Parameters
//
// - token: The ERC721 address.
// - sender: The transfer sender address.
// - receiver: The transfer receiver address.
// - tokenId: The token ID to transfer.
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
// the first four bytes of the zero slot `0x60`. So we overwrite these values
// at the end to ensure the free memory pointer and zero slot are correct.
//
// ### Procedures
//
// 01. Load the free memory pointer.
// 02. Store the `transferFromSelector`.
// 03. Store the `sender`.
// 04. Store the `receiver`.
// 05. Store the `tokenId`.
// 06. Call the `token` contract, caching the `success` boolean.
// 07. Check that either the `returndatasize` is zero or the returned value is.
//     non-zero.
// 08. Logical AND the success conditions.
// 09. Restore the free memory pointer.
// 10. Restore the zero slot.
function transferFrom(
    ERC721 token,
    address sender,
    address receiver,
    uint256 tokenId
) returns (bool success) {
    assembly ("memory-safe") {
        let fmp := mload(0x40)

        mstore(0x00, transferFromSelector)

        mstore(0x04, sender)

        mstore(0x24, receiver)

        mstore(0x44, tokenId)

        success := call(gas(), token, 0x00, 0x00, 0x64, 0x00, 0x00)

        mstore(0x40, fmp)
    }
}
