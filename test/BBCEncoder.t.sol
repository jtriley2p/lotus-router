// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Test } from "lib/forge-std/src/Test.sol";

import { Action } from "src/types/Action.sol";
import { BBCEncoder } from "src/util/BBCEncoder.sol";

contract BBCEncoderTest is Test {
    function testEncodeSwapUniV2() public view {
        bool canFail = false;

        uint8 pairLen = 0x04;
        address pair = address(0xaabbccdd);

        uint8 amount0OutByteLen = 0x01;
        uint8 amount0Out = 0x45;

        uint8 amount1OutBytelen = 0x01;
        uint8 amount1Out = 0x46;

        uint8 toLen = 0x04;
        address to = address(0xeeffaabb);

        bytes memory data = hex"deadbeef";

        bytes memory encoded =
            BBCEncoder.encodeSwapUniV2(canFail, pair, amount0Out, amount1Out, to, data);

        bytes memory expected = abi.encodePacked(
            uint8(Action.SwapUniV2),
            canFail,
            pairLen,
            uint32(uint160(pair)),
            amount0OutByteLen,
            amount0Out,
            amount1OutBytelen,
            amount1Out,
            toLen,
            uint32(uint160(to)),
            uint32(data.length),
            data
        );

        assertEq(keccak256(encoded), keccak256(expected));
    }

    function testFuzzEncodeSwapUniV2(
        bool canFail,
        uint8 pairByteLen,
        uint160 pair,
        uint8 amount0OutByteLen,
        uint256 amount0Out,
        uint8 amount1OutByteLen,
        uint256 amount1Out,
        uint8 toByteLen,
        uint160 to,
        bytes memory data
    ) public view {
        pairByteLen = uint8(bound(pairByteLen, 0, 20));
        pair = uint160(bound(pair, __min(pairByteLen), __max(pairByteLen)));

        amount0OutByteLen = uint8(bound(amount0OutByteLen, 0, 32));
        amount0Out = bound(amount0Out, __min(amount0OutByteLen), __max(amount0OutByteLen));

        amount1OutByteLen = uint8(bound(amount1OutByteLen, 0, 32));
        amount1Out = bound(amount1Out, __min(amount1OutByteLen), __max(amount1OutByteLen));

        toByteLen = uint8(bound(toByteLen, 0, 20));
        to = uint160(bound(to, __min(toByteLen), __max(toByteLen)));

        bytes memory encoded = BBCEncoder.encodeSwapUniV2(
            canFail, address(pair), amount0Out, amount1Out, address(to), data
        );

        bytes memory expected = abi.encodePacked(uint8(Action.SwapUniV2), canFail);

        expected = __pack(expected, pairByteLen, pair);
        expected = __pack(expected, amount0OutByteLen, amount0Out);
        expected = __pack(expected, amount1OutByteLen, amount1Out);
        expected = __pack(expected, toByteLen, to);

        expected = abi.encodePacked(expected, uint32(data.length), data);

        assertEq(keccak256(encoded), keccak256(expected));
    }

    function testEncodeTransferERC20() public pure {
        bool canFail = false;

        uint8 tokenByteLen = 0x04;
        address token = address(0xaabbccdd);

        uint8 receiverByteLen = 0x04;
        address receiver = address(0xeeffaabb);

        uint8 amountByteLen = 0x01;
        uint8 amount = 0x02;

        bytes memory encoded = BBCEncoder.encodeTransferERC20(canFail, token, receiver, amount);

        bytes memory expected = abi.encodePacked(
            uint8(Action.TransferERC20),
            canFail,
            tokenByteLen,
            uint32(uint160(token)),
            receiverByteLen,
            uint32(uint160(receiver)),
            amountByteLen,
            amount
        );

        assertEq(keccak256(encoded), keccak256(expected));
    }

    function testFuzzEncodeTransferERC20(
        bool canFail,
        uint8 tokenByteLen,
        uint160 token,
        uint8 receiverByteLen,
        uint160 receiver,
        uint8 amountByteLen,
        uint256 amount
    ) public {
        tokenByteLen = uint8(bound(tokenByteLen, 0, 20));
        token = uint160(bound(token, __min(tokenByteLen), __max(tokenByteLen)));

        receiverByteLen = uint8(bound(receiverByteLen, 0, 20));
        receiver = uint160(bound(receiver, __min(receiverByteLen), __max(receiverByteLen)));

        amountByteLen = uint8(bound(amountByteLen, 0, 32));
        amount = bound(amount, __min(amountByteLen), __max(amountByteLen));

        bytes memory encoded =
            BBCEncoder.encodeTransferERC20(canFail, address(token), address(receiver), amount);

        bytes memory expected = abi.encodePacked(uint8(Action.TransferERC20), canFail);

        expected = __pack(expected, tokenByteLen, token);
        expected = __pack(expected, receiverByteLen, receiver);
        expected = __pack(expected, amountByteLen, amount);

        emit log_bytes(encoded);
        emit log_bytes(expected);

        assertEq(keccak256(encoded), keccak256(expected));
    }

    function __min(
        uint8 byteLen
    ) internal pure returns (uint256) {
        if (byteLen == 0) return 0;

        return 2 ** ((byteLen - 1) * 8);
    }

    function __max(
        uint8 byteLen
    ) internal pure returns (uint256) {
        if (byteLen == 32) return type(uint256).max;

        return 2 ** (byteLen * 8) - 1;
    }

    function __pack(
        bytes memory data,
        uint8 wordLen,
        uint256 word
    ) internal pure returns (bytes memory) {
        if (wordLen == 0) return abi.encodePacked(data, wordLen);
        if (wordLen == 1) return abi.encodePacked(data, wordLen, uint8(word));
        if (wordLen == 2) return abi.encodePacked(data, wordLen, uint16(word));
        if (wordLen == 3) return abi.encodePacked(data, wordLen, uint24(word));
        if (wordLen == 4) return abi.encodePacked(data, wordLen, uint32(word));
        if (wordLen == 5) return abi.encodePacked(data, wordLen, uint40(word));
        if (wordLen == 6) return abi.encodePacked(data, wordLen, uint48(word));
        if (wordLen == 7) return abi.encodePacked(data, wordLen, uint56(word));
        if (wordLen == 8) return abi.encodePacked(data, wordLen, uint64(word));
        if (wordLen == 9) return abi.encodePacked(data, wordLen, uint72(word));
        if (wordLen == 10) return abi.encodePacked(data, wordLen, uint80(word));
        if (wordLen == 11) return abi.encodePacked(data, wordLen, uint88(word));
        if (wordLen == 12) return abi.encodePacked(data, wordLen, uint96(word));
        if (wordLen == 13) return abi.encodePacked(data, wordLen, uint104(word));
        if (wordLen == 14) return abi.encodePacked(data, wordLen, uint112(word));
        if (wordLen == 15) return abi.encodePacked(data, wordLen, uint120(word));
        if (wordLen == 16) return abi.encodePacked(data, wordLen, uint128(word));
        if (wordLen == 17) return abi.encodePacked(data, wordLen, uint136(word));
        if (wordLen == 18) return abi.encodePacked(data, wordLen, uint144(word));
        if (wordLen == 19) return abi.encodePacked(data, wordLen, uint152(word));
        if (wordLen == 20) return abi.encodePacked(data, wordLen, uint160(word));
        if (wordLen == 21) return abi.encodePacked(data, wordLen, uint168(word));
        if (wordLen == 22) return abi.encodePacked(data, wordLen, uint176(word));
        if (wordLen == 23) return abi.encodePacked(data, wordLen, uint184(word));
        if (wordLen == 24) return abi.encodePacked(data, wordLen, uint192(word));
        if (wordLen == 25) return abi.encodePacked(data, wordLen, uint200(word));
        if (wordLen == 26) return abi.encodePacked(data, wordLen, uint208(word));
        if (wordLen == 27) return abi.encodePacked(data, wordLen, uint216(word));
        if (wordLen == 28) return abi.encodePacked(data, wordLen, uint224(word));
        if (wordLen == 29) return abi.encodePacked(data, wordLen, uint232(word));
        if (wordLen == 30) return abi.encodePacked(data, wordLen, uint240(word));
        if (wordLen == 31) return abi.encodePacked(data, wordLen, uint248(word));
        if (wordLen == 32) return abi.encodePacked(data, wordLen, uint256(word));
        revert("unreachable");
    }
}
