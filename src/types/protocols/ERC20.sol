// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

type ERC20 is address;

using { transfer, transferFrom } for ERC20 global;

uint256 constant transferSelector =
    0xa9059cbb00000000000000000000000000000000000000000000000000000000;
uint256 constant transferFromSelector =
    0x23b872dd00000000000000000000000000000000000000000000000000000000;

// ## Execute ERC20 transfer
//
// ### Parameters
//
// - token: The ERC20 address.
// - receiver: The transfer receiver address.
// - amount: The transfer amount.
//
// ### Returns
//
// - success: returns True if the transfer succeeded
//
// ### Notes
//
// ERC20 conformity is a debacle. Some never return anything, some revert on
// failure, some return false on failure. So we check that the execution context
// did not revert and that either nothing was returned, or if something was
// returned, it is a nonzero value (not false).
//
// Since the calldata of this is small, we allocate the memory for it in the
// scratchspace normally used by Solidity for keccak hashing. This reduces
// overall memory allocations. However, it's worth noting that doing this
// occupies the first 68 bytes, which overwrites the first four bytes of memory
// slot `0x40`, which contains the free memory pointer. So we overwrite these
// upper bytes at the end to ensure the free memory pointer is correct.
//
// ### Procedures
//
// 01. Store the `transferSelector`.
// 02. Store the `receiver`.
// 03. Store the `amount`.
// 04. Call the `token` contract, caching the `success` boolean.
// 05. Check that either the `returndatasize` is zero or the returned value is.
//     non-zero.
// 06. Logical AND the success conditions.
// 07. Store zero to restore the upper bytes of the free memory pointer to zero.
function transfer(ERC20 token, address receiver, uint256 amount) returns (bool success) {
    assembly ("memory-safe") {
        mstore(0x00, transferSelector)

        mstore(0x04, receiver)

        mstore(0x24, amount)

        success := call(gas(), token, 0x00, 0x00, 0x44, 0x00, 0x20)

        let successERC20 := or(iszero(returndatasize()), eq(0x01, mload(0x00)))

        success := and(success, successERC20)

        mstore(0x24, 0x00)
    }
}

// ## Execute ERC20 transfer
//
// ### Parameters
//
// - token: The ERC20 address.
// - sender: The transfer sender address.
// - receiver: The transfer receiver address.
// - amount: The transfer amount.
//
// ### Returns
//
// - success: returns True if the transfer succeeded
//
// ### Notes
//
// ERC20 conformity is a debacle. Some never return anything, some revert on
// failure, some return false on failure. So we check that the execution context
// did not revert and that either nothing was returned, or if something was
// returned, it is a nonzero value (not false).
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
// 05. Store the `amount`.
// 06. Call the `token` contract, caching the `success` boolean.
// 07. Check that either the `returndatasize` is zero or the returned value is.
//     non-zero.
// 08. Logical AND the success conditions.
// 09. Restore the free memory pointer.
// 10. Restore the zero slot.
function transferFrom(
    ERC20 token,
    address sender,
    address receiver,
    uint256 amount
) returns (bool success) {
    assembly ("memory-safe") {
        let fmp := mload(0x40)

        mstore(0x00, transferFromSelector)

        mstore(0x04, sender)

        mstore(0x24, receiver)

        mstore(0x44, amount)

        success := call(gas(), token, 0x00, 0x00, 0x64, 0x00, 0x20)

        let successERC20 := or(iszero(returndatasize()), eq(0x01, mload(0x00)))

        success := and(success, successERC20)

        mstore(0x40, fmp)

        mstore(0x60, 0x00)
    }
}
