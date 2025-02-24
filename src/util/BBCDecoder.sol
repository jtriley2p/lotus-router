// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";

import { ERC20 } from "src/types/protocols/ERC20.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";

// ## Decoder
//
// Inspired by the calldata schema of BigBrainChad.eth
//
// ### Encoding Overview
//
// Statically sized calldata arguments of 8 bits or less are encoded in place.
//
// Statically sized calldata arguments of 9 to 256 bits are prefixed with their
// byte length (as an 8 bit integer) followed by the argument, compacted to its
// byte length. This is to handle the common case of the majority of bits being
// unoccupied.
//
// Dynamically sized calldata arguments are prefixed with a 32 bit integer
// indicating its byte length, followed by the bytes themselves. This is worth
// exploring in the future as to whether or not the upper bits of the byte
// length are unoccupied enough to justify an encoding as mentioned in the
// statically sized calldata arguments above.
library BBCDecoder {
    uint256 internal constant u8Shr = 0xf8;
    uint256 internal constant u32Shr = 0xe0;

    function decodeSwapUniV2(
        Ptr ptr
    )
        internal
        pure
        returns (
            Ptr nextPtr,
            bool canFail,
            UniV2Pair pair,
            uint256 amount0Out,
            uint256 amount1Out,
            address to,
            BytesCalldata data
        )
    {
        assembly {
            let nextByteLen, nextBitShift
            nextPtr := ptr

            canFail := shr(u8Shr, calldataload(nextPtr))

            nextPtr := add(nextPtr, 0x01)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            pair := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            amount0Out := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            amount1Out := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            to := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u32Shr, calldataload(nextPtr))

            data := nextPtr

            nextPtr := add(nextPtr, 0x04)

            nextPtr := add(nextPtr, nextByteLen)
        }
    }

    function decodeTransferERC20(
        Ptr ptr
    )
        internal
        pure
        returns (Ptr nextPtr, bool canFail, ERC20 token, address receiver, uint256 amount)
    {
        assembly {
            let nextByteLen, nextBitShift
            nextPtr := ptr

            canFail := shr(u8Shr, calldataload(nextPtr))

            nextPtr := add(nextPtr, 0x01)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            token := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            receiver := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            amount := shr(nextBitShift, calldataload(nextPtr))
        }
    }

    function decodeTransferFromERC20(
        Ptr ptr
    )
        internal
        pure
        returns (
            Ptr nextPtr,
            bool canFail,
            ERC20 token,
            address sender,
            address receiver,
            uint256 amount
        )
    {
        assembly {
            let nextByteLen, nextBitShift
            nextPtr := ptr

            canFail := shr(u8Shr, calldataload(nextPtr))

            nextPtr := add(nextPtr, 0x01)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            token := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            sender := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            receiver := shr(nextBitShift, calldataload(nextPtr))

            nextPtr := add(nextPtr, nextByteLen)
            nextByteLen := shr(u8Shr, calldataload(nextPtr))
            nextBitShift := sub(0x0100, mul(0x08, nextByteLen))
            nextPtr := add(nextPtr, 0x01)

            amount := shr(nextBitShift, calldataload(nextPtr))
        }
    }
}
