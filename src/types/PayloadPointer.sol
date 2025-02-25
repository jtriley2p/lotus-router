// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Action } from "src/types/Action.sol";
import { Error } from "src/types/Error.sol";

type Ptr is uint256;

using { nextAction } for Ptr global;

uint256 constant takeAction = 0x19ff8034;
uint256 constant uniswapV2Call = 0x10d1e85c;

// ## Finds the Payload Pointer
//
// ### Returns
//
// - ptr: A pointer to the payload in calldata
//
// ### Reverts
//
// - If the selector does not match any expected ones.
//
// ### Notes
//
// For `callLotusRouter()`, the payload immediately follows the selector at
// index four (`0x04`).
//
// For `uniswapV2Call(address,uint256,uint256,bytes)`, the payload is in the
// fourth parameter, `bytes calldata data`, where the offset is at index 100,
// the length is at index 132, and the data itself is at index 164 (`0xa4`).
function findPtr() pure returns (Ptr) {
    uint256 selector = uint256(uint32(msg.sig));

    if (selector == takeAction) {
        return Ptr.wrap(0x04);
    }
    if (selector == uniswapV2Call) {
        return Ptr.wrap(0xa4);
    } else {
        revert Error.UnexpectedEntryPoint();
    }
}

// ## Loads the Next Action from Calldata
//
// ## Parameters
//
// - ptr: The payload pointer
//
// ## Returns
//
// - ptr: The incremented payload pointer
// - action: The loaded action
//
// ## Notes
//
// The `ptr` parameter is incremented in place to allow continuous parsing.
function nextAction(
    Ptr ptr
) pure returns (Ptr, Action action) {
    assembly {
        action := shr(0xf8, calldataload(ptr))

        ptr := add(ptr, 0x01)
    }

    return (ptr, action);
}
