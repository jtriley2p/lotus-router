// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { BBCDecoder } from "src/util/BBCDecoder.sol";
import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";

contract BBCDecoderMock {
    function decodeSwapUniV2(bytes calldata encoded) public pure returns (
        bool canFail,
        UniV2Pair pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) {
        Ptr ptr;
        BytesCalldata packedData;

        // add 0x01 bc the first byte is the `Action` opcode, it's not decoded
        assembly { ptr := add(0x01, encoded.offset) }

        (, canFail, pair, amount0Out, amount1Out, to, packedData) = BBCDecoder.decodeSwapUniV2(ptr);

        assembly {
            let fmp := mload(0x40)

            data := fmp

            let len := shr(0xe0, calldataload(packedData))

            mstore(fmp, len)

            fmp := add(fmp, 0x20)

            calldatacopy(fmp, add(packedData, 0x04), len)

            fmp := add(fmp, len)

            mstore(0x40, fmp)
        }
    }
}
