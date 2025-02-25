// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Test } from "lib/forge-std/src/Test.sol";
import { BBCDecoderMock } from "test/mock/BBCDecoderMock.sol";

import { Action } from "src/types/Action.sol";
import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";

import { ERC20 } from "src/types/protocols/ERC20.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { BBCDecoder } from "src/util/BBCDecoder.sol";
import { BBCEncoder } from "src/util/BBCEncoder.sol";

contract BBCDecoderTest is Test {
    BBCDecoderMock decoder;

    function setUp() public {
        decoder = new BBCDecoderMock();
    }

    function testDecodeSwapUniV2() public view {
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

    function testFuzzDecodeSwapUniv2(
        bool expectedCanFail,
        address expectedPair,
        uint8 expectedAmount0Out,
        uint8 expectedAmount1Out,
        address expectedTo,
        bytes memory expectedData
    ) public view {
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

    function testDecodeTransferERC20() public view {
        bool expectedCanFail = true;
        address expectedToken = address(0xaabbccdd);
        address expectedReceiver = address(0xeeffaabb);
        uint8 expectedAmount = 0x45;

        bytes memory encoded = BBCEncoder.encodeTransferERC20(
            expectedCanFail, expectedToken, expectedReceiver, expectedAmount
        );

        (bool canFail, ERC20 token, address receiver, uint256 amount) =
            decoder.decodeTransferERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }

    function tesFuzzDecodeTransferERC20(
        bool expectedCanFail,
        address expectedToken,
        address expectedReceiver,
        uint8 expectedAmount
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferERC20(
            expectedCanFail, expectedToken, expectedReceiver, expectedAmount
        );

        (bool canFail, ERC20 token, address receiver, uint256 amount) =
            decoder.decodeTransferERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }

    function testDecodeTransferFromERC20() public view {
        bool expectedCanFail = true;
        address expectedToken = address(0xaabbccdd);
        address expectedSender = address(0xeeffaabb);
        address expectedReceiver = address(0xccddeeff);
        uint8 expectedAmount = 0x45;

        bytes memory encoded = BBCEncoder.encodeTransferFromERC20(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedAmount
        );

        (bool canFail, ERC20 token, address sender, address receiver, uint256 amount) =
            decoder.decodeTransferFromERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }

    function testFuzzDecodeTransferFromERC20(
        bool expectedCanFail,
        address expectedToken,
        address expectedSender,
        address expectedReceiver,
        uint8 expectedAmount
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferFromERC20(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedAmount
        );

        (bool canFail, ERC20 token, address sender, address receiver, uint256 amount) =
            decoder.decodeTransferFromERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }

    function testDecodeTransferFromERC721() public view {
        bool expectedCanFail = true;
        address expectedToken = address(0xaabbccdd);
        address expectedSender = address(0xeeffaabb);
        address expectedReceiver = address(0xccddeeff);
        uint8 expectedTokenId = 0x45;

        bytes memory encoded = BBCEncoder.encodeTransferFromERC20(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedTokenId
        );

        (bool canFail, ERC20 token, address sender, address receiver, uint256 tokenId) =
            decoder.decodeTransferFromERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
    }

    function testFuzzDecodeTransferFromERC721(
        bool expectedCanFail,
        address expectedToken,
        address expectedSender,
        address expectedReceiver,
        uint8 expectedTokenid
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferFromERC20(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedTokenid
        );

        (bool canFail, ERC20 token, address sender, address receiver, uint256 tokenId) =
            decoder.decodeTransferFromERC20(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC20.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenid);
    }
}
