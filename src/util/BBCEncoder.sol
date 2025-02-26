// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Action } from "src/types/Action.sol";

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
//
// ### Notes
//
// This encoder, while in the source directory of the Lotus Router and its
// libraries, is not rigorously optimized, as the encoding scheme is meant to
// reduce the cost of the smart contract entry point, given the unusually high
// cost per byte of calldata. This is largely in service of testing libraries
// and more offchain periphery will be developed in the future to ensure users
// may interface with the Lotus Router in a reasonably safe way.
//
// Also, the encoder largely uses assembly nonetheless, as Solidity does not
// support fully dependent types, which would allow for run-time
// parameterization of value byte lengths.
library BBCEncoder {
    function encodeSwapUniV2(
        bool canFail,
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) internal view returns (bytes memory) {
        Action action = Action.SwapUniV2;
        uint8 pairByteLen = byteLen(pair);
        uint8 amount0OutByteLen = byteLen(amount0Out);
        uint8 amount1OutByteLen = byteLen(amount1Out);
        uint8 toByteLen = byteLen(to);
        uint256 dataByteLen = data.length;

        bytes memory encoded = new bytes(
            10 + pairByteLen + amount0OutByteLen + amount1OutByteLen + toByteLen + dataByteLen
        );

        assembly ("memory-safe") {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, pairByteLen))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, pairByteLen)), pair))
            ptr := add(ptr, pairByteLen)

            mstore(ptr, shl(0xf8, amount0OutByteLen))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, amount0OutByteLen)), amount0Out))
            ptr := add(ptr, amount0OutByteLen)

            mstore(ptr, shl(0xf8, amount1OutByteLen))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, amount1OutByteLen)), amount1Out))
            ptr := add(ptr, amount1OutByteLen)

            mstore(ptr, shl(0xf8, toByteLen))
            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, toByteLen)), to))
            ptr := add(ptr, toByteLen)

            mstore(ptr, shl(0xe0, dataByteLen))
            ptr := add(ptr, 0x04)

            pop(staticcall(gas(), 0x04, add(data, 0x20), dataByteLen, ptr, dataByteLen))
        }

        return encoded;
    }

    function encodeTransferERC20(
        bool canFail,
        address token,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        Action action = Action.TransferERC20;
        uint8 tokenByteLen = byteLen(token);
        uint8 receiverByteLen = byteLen(receiver);
        uint8 amountByteLen = byteLen(amount);

        bytes memory encoded = new bytes(5 + tokenByteLen + receiverByteLen + amountByteLen);

        assembly ("memory-safe") {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, tokenByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, tokenByteLen)), token))

            ptr := add(ptr, tokenByteLen)

            mstore(ptr, shl(0xf8, receiverByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, receiverByteLen)), receiver))

            ptr := add(ptr, receiverByteLen)

            mstore(ptr, shl(0xf8, amountByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, amountByteLen)), amount))
        }

        return encoded;
    }

    function encodeTransferFromERC20(
        bool canFail,
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) public pure returns (bytes memory) {
        Action action = Action.TransferFromERC20;
        uint8 tokenByteLen = byteLen(token);
        uint8 senderByteLen = byteLen(sender);
        uint8 receiverByteLen = byteLen(receiver);
        uint8 amountByteLen = byteLen(amount);

        bytes memory encoded =
            new bytes(6 + tokenByteLen + senderByteLen + receiverByteLen + amountByteLen);

        assembly ("memory-safe") {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, tokenByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, tokenByteLen)), token))

            ptr := add(ptr, tokenByteLen)

            mstore(ptr, shl(0xf8, senderByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, senderByteLen)), sender))

            ptr := add(ptr, senderByteLen)

            mstore(ptr, shl(0xf8, receiverByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, receiverByteLen)), receiver))

            ptr := add(ptr, receiverByteLen)

            mstore(ptr, shl(0xf8, amountByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, amountByteLen)), amount))
        }

        return encoded;
    }

    function encodeTransferFromERC721(
        bool canFail,
        address token,
        address sender,
        address receiver,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        Action action = Action.TransferFromERC20;
        uint8 tokenByteLen = byteLen(token);
        uint8 senderByteLen = byteLen(sender);
        uint8 receiverByteLen = byteLen(receiver);
        uint8 tokenIdByteLen = byteLen(tokenId);

        bytes memory encoded =
            new bytes(6 + tokenByteLen + senderByteLen + receiverByteLen + tokenIdByteLen);

        assembly ("memory-safe") {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, tokenByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, tokenByteLen)), token))

            ptr := add(ptr, tokenByteLen)

            mstore(ptr, shl(0xf8, senderByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, senderByteLen)), sender))

            ptr := add(ptr, senderByteLen)

            mstore(ptr, shl(0xf8, receiverByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, receiverByteLen)), receiver))

            ptr := add(ptr, receiverByteLen)

            mstore(ptr, shl(0xf8, tokenIdByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, tokenIdByteLen)), tokenId))
        }

        return encoded;
    }

    function encodeTransferERC6909(
        bool canFail,
        address multitoken,
        address receiver,
        uint256 tokenId,
        uint256 amount
    ) public pure returns (bytes memory) {
        Action action = Action.TransferERC6909;
        uint8 multitokenByteLen = byteLen(multitoken);
        uint8 receiverByteLen = byteLen(receiver);
        uint8 tokenIdByteLen = byteLen(tokenId);
        uint8 amountByteLen = byteLen(amount);

        bytes memory encoded = new bytes(
            6 + multitokenByteLen + receiverByteLen + tokenIdByteLen + amountByteLen
        );

        assembly ("memory-safe") {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, multitokenByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, multitokenByteLen)), multitoken))

            ptr := add(ptr, multitokenByteLen)

            mstore(ptr, shl(0xf8, receiverByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, receiverByteLen)), receiver))

            ptr := add(ptr, receiverByteLen)

            mstore(ptr, shl(0xf8, tokenIdByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, tokenIdByteLen)), tokenId))

            ptr := add(ptr, tokenIdByteLen)

            mstore(ptr, shl(0xf8, amountByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, amountByteLen)), amount))
        }

        return encoded;
    }

    function encodeDepositWETH(
        bool canFail,
        address weth,
        uint256 value
    ) public pure returns (bytes memory) {
        Action action = Action.DepositWETH;
        uint8 wethByteLen = byteLen(weth);
        uint8 valueByteLen = byteLen(value);

        bytes memory encoded = new bytes(4 + wethByteLen + valueByteLen);

        assembly {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, wethByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, wethByteLen)), weth))

            ptr := add(ptr, wethByteLen)

            mstore(ptr, shl(0xf8, valueByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, valueByteLen)), value))
        }

        return encoded;
    }

    function encodeWithdrawWETH(
        bool canFail,
        address weth,
        uint256 value
    ) public pure returns (bytes memory) {
        Action action = Action.WithdrawWETH;
        uint8 wethByteLen = byteLen(weth);
        uint8 valueByteLen = byteLen(value);

        bytes memory encoded = new bytes(4 + wethByteLen + valueByteLen);

        assembly {
            let ptr := add(encoded, 0x20)

            mstore(ptr, shl(0xf8, action))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, canFail))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(0xf8, wethByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, wethByteLen)), weth))

            ptr := add(ptr, wethByteLen)

            mstore(ptr, shl(0xf8, valueByteLen))

            ptr := add(ptr, 0x01)

            mstore(ptr, shl(sub(0x0100, mul(0x08, valueByteLen)), value))
        }

        return encoded;
    }

    function byteLen(
        uint256 word
    ) internal pure returns (uint8) {
        for (uint8 i = 32; i > 0; i--) {
            if (word >> ((i - 1) * 8) != 0) return i;
        }

        return 0;
    }

    function byteLen(
        address addr
    ) internal pure returns (uint8) {
        uint160 word = uint160(addr);

        for (uint8 i = 20; i > 0; i--) {
            if (word >> ((i - 1) * 8) != 0) return i;
        }

        return 0;
    }
}
