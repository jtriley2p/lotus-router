// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

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
            uint8(Action.UniV2Swap),
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
}
