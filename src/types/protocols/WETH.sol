// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

type WETH is address;

using { deposit, withdraw } for WETH global;

uint256 constant withdrawSelector =
    0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;

// ## Execute WETH deposit
//
// ### Parameters
//
// - value: The deposit amount.
//
// ### Returns
//
// - success: returns True if the deposit succeeded
//
// ### Notes
//
// Hard-coding the WETH address would be profitable for single-chain
// implementations, though we're focusing on multi-chain deployability, so our
// implementation will require it to be passed in as calldata.
//
// Also, using the fallback function with no calldata is marginally cheaper than
// using the `deposit()` function, as Solidity short circuits the selector
// dispatcher in WETH if the `calldatasize` is zero.
//
// ### Procedures
//
// 01. Call the `weth` contract, returning the boolean.
function deposit(WETH weth, uint256 value) returns (bool success) {
    assembly ("memory-safe") {
        success := call(gas(), weth, value, 0x00, 0x00, 0x00, 0x00)
    }
}

// ## Execute WETH withdraw
//
// ### Parameters
//
// - value: The withdraw amount.
//
// ### Returns
//
// - success: returns True if the withdraw succeeded
//
// ### Notes
//
// Hard-coding the WETH address would be profitable for single-chain
// implementations, though we're focusing on multi-chain deployability, so our
// implementation will require it to be passed in as calldata.
//
// ### Procedures
//
// 01. Store the `withdrawSelector`.
// 02. Store the `value`.
// 03. Call the `weth` contract, returning the boolean.
function withdraw(WETH weth, uint256 value) returns (bool success) {
    assembly ("memory-safe") {
        mstore(0x00, withdrawSelector)

        mstore(0x04, value)

        success := call(gas(), weth, 0x00, 0x00, 0x24, 0x00, 0x00)
    }
}
