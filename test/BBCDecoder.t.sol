// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Test } from "lib/forge-std/src/Test.sol";
import { BBCDecoderMock } from "test/mock/BBCDecoderMock.sol";

import { Action } from "src/types/Action.sol";
import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";
import { ERC20 } from "src/types/protocols/ERC20.sol";

import { ERC6909 } from "src/types/protocols/ERC6909.sol";
import { ERC721 } from "src/types/protocols/ERC721.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { WETH } from "src/types/protocols/WETH.sol";
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

        bytes memory encoded = BBCEncoder.encodeTransferFromERC721(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedTokenId
        );

        (bool canFail, ERC721 token, address sender, address receiver, uint256 tokenId) =
            decoder.decodeTransferFromERC721(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC721.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
    }

    function testFuzzDecodeTransferFromERC721(
        bool expectedCanFail,
        address expectedToken,
        address expectedSender,
        address expectedReceiver,
        uint8 expectedTokenId
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferFromERC721(
            expectedCanFail, expectedToken, expectedSender, expectedReceiver, expectedTokenId
        );

        (bool canFail, ERC721 token, address sender, address receiver, uint256 tokenId) =
            decoder.decodeTransferFromERC721(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC721.unwrap(token), expectedToken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
    }

    function testDecodeTransferERC6909() public view {
        bool expectedCanFail = false;
        address expectedMultitoken = address(0xaabbccdd);
        address expectedReceiver = address(0xeeffaabb);
        uint256 expectedTokenId = 0x45;
        uint256 expectedAmount = 0x46;

        bytes memory encoded = BBCEncoder.encodeTransferERC6909(
            expectedCanFail, expectedMultitoken, expectedReceiver, expectedTokenId, expectedAmount
        );

        (bool canFail, ERC6909 multitoken, address receiver, uint256 tokenId, uint256 amount) =
            decoder.decodeTransferERC6909(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC6909.unwrap(multitoken), expectedMultitoken);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
        assertEq(amount, expectedAmount);
    }

    function testFuzzDecodeTransferERC6909(
        bool expectedCanFail,
        address expectedMultitoken,
        address expectedReceiver,
        uint256 expectedTokenId,
        uint256 expectedAmount
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferERC6909(
            expectedCanFail, expectedMultitoken, expectedReceiver, expectedTokenId, expectedAmount
        );

        (bool canFail, ERC6909 multitoken, address receiver, uint256 tokenId, uint256 amount) =
            decoder.decodeTransferERC6909(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC6909.unwrap(multitoken), expectedMultitoken);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
        assertEq(amount, expectedAmount);
    }

    function testDecodeTransferFromERC6909() public view {
        bool expectedCanFail = false;
        address expectedMultitoken = address(0xaabbccdd);
        address expectedSender = address(0xeeffaabb);
        address expectedReceiver = address(0xccddeeff);
        uint256 expectedTokenId = 0x45;
        uint256 expectedAmount = 0x46;

        bytes memory encoded = BBCEncoder.encodeTransferFromERC6909(
            expectedCanFail,
            expectedMultitoken,
            expectedSender,
            expectedReceiver,
            expectedTokenId,
            expectedAmount
        );

        (
            bool canFail,
            ERC6909 multitoken,
            address sender,
            address receiver,
            uint256 tokenId,
            uint256 amount
        ) = decoder.decodeTransferFromERC6909(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC6909.unwrap(multitoken), expectedMultitoken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
        assertEq(amount, expectedAmount);
    }

    function testFuzzDecodeTransferFromERC6909(
        bool expectedCanFail,
        address expectedMultitoken,
        address expectedSender,
        address expectedReceiver,
        uint256 expectedTokenId,
        uint256 expectedAmount
    ) public view {
        bytes memory encoded = BBCEncoder.encodeTransferFromERC6909(
            expectedCanFail,
            expectedMultitoken,
            expectedSender,
            expectedReceiver,
            expectedTokenId,
            expectedAmount
        );

        (
            bool canFail,
            ERC6909 multitoken,
            address sender,
            address receiver,
            uint256 tokenId,
            uint256 amount
        ) = decoder.decodeTransferFromERC6909(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(ERC6909.unwrap(multitoken), expectedMultitoken);
        assertEq(sender, expectedSender);
        assertEq(receiver, expectedReceiver);
        assertEq(tokenId, expectedTokenId);
        assertEq(amount, expectedAmount);
    }

    function testDecodeDepositWETH() public view {
        bool expectedCanFail = false;
        address expectedWeth = address(0xaabbccdd);
        uint256 expectedValue = 0x45;

        bytes memory encoded =
            BBCEncoder.encodeDepositWETH(expectedCanFail, expectedWeth, expectedValue);

        (bool canFail, WETH weth, uint256 value) = decoder.decodeDepositWETH(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(WETH.unwrap(weth), expectedWeth);
        assertEq(value, expectedValue);
    }

    function testFuzzDecodeDepositWETH(
        bool expectedCanFail,
        address expectedWeth,
        uint8 expectedValue
    ) public view {
        bytes memory encoded =
            BBCEncoder.encodeDepositWETH(expectedCanFail, expectedWeth, expectedValue);

        (bool canFail, WETH weth, uint256 value) = decoder.decodeDepositWETH(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(WETH.unwrap(weth), expectedWeth);
        assertEq(value, expectedValue);
    }

    function testDecodWithdrawWETH() public view {
        bool expectedCanFail = false;
        address expectedWeth = address(0xaabbccdd);
        uint256 expectedValue = 0x45;

        bytes memory encoded =
            BBCEncoder.encodeWithdrawWETH(expectedCanFail, expectedWeth, expectedValue);

        (bool canFail, WETH weth, uint256 value) = decoder.decodeWithdrawWETH(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(WETH.unwrap(weth), expectedWeth);
        assertEq(value, expectedValue);
    }

    function testFuzzDecodeWithdrawWETH(
        bool expectedCanFail,
        address expectedWeth,
        uint8 expectedValue
    ) public view {
        bytes memory encoded =
            BBCEncoder.encodeWithdrawWETH(expectedCanFail, expectedWeth, expectedValue);

        (bool canFail, WETH weth, uint256 value) = decoder.decodeWithdrawWETH(encoded);

        assertEq(canFail, expectedCanFail);
        assertEq(WETH.unwrap(weth), expectedWeth);
        assertEq(value, expectedValue);
    }
}
