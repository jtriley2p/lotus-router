// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Test } from "lib/forge-std/src/Test.sol";
import { BBCDecoderMock } from "test/mock/BBCDecoderMock.sol";

import { Action } from "src/types/Action.sol";
import { BytesCalldata } from "src/types/BytesCalldata.sol";

import { Ptr } from "src/types/PayloadPointer.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { BBCDecoder } from "src/util/BBCDecoder.sol";
import { BBCEncoder } from "src/util/BBCEncoder.sol";

contract BBCDecoderTest is Test {
    BBCDecoderMock decoder;

    function setUp() public {
        decoder = new BBCDecoderMock();
    }

    function testDecodeSwapUniV2() public {
        bool expectedCanFail = true;
        address expectedPair = address(0xaabbccdd);
        uint8 expectedAmount0Out = 0x45;
        uint8 expectedAmount1Out = 0x46;
        address expectedTo = address(0xeeffaabb);
        bytes memory expectedData = hex"deadbeef";

        bytes memory encoded = BBCEncoder.encodeSwapUniV2(
            expectedCanFail,
            expectedPair,
            expectedAmount0Out,
            expectedAmount1Out,
            expectedTo,
            expectedData
        );

        (
            bool canFail,
            UniV2Pair pair,
            uint256 amount0Out,
            uint256 amount1Out,
            address to,
            bytes memory data
        ) = decoder.decodeSwapUniV2(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(UniV2Pair.unwrap(pair), expectedPair);
        assertEq(amount0Out, expectedAmount0Out);
        assertEq(amount1Out, expectedAmount1Out);
        assertEq(to, expectedTo);
        assertEq(keccak256(data), keccak256(expectedData));
    }
}
