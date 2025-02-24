// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";

import { ERC20 } from "src/types/protocols/ERC20.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { BBCDecoder } from "src/util/BBCDecoder.sol";

contract BBCDecoderMock {
    using BBCDecoder for Ptr;

    function decodeSwapUniV2(
        bytes calldata encoded
    )
        public
        pure
        returns (
            bool canFail,
            UniV2Pair pair,
            uint256 amount0Out,
            uint256 amount1Out,
            address to,
            bytes memory data
        )
    {
        Ptr ptr;
        BytesCalldata packedData;

        // add 0x01 bc the first byte is the `Action` opcode, it's not decoded
        assembly {
            ptr := add(0x01, encoded.offset)
        }

        (, canFail, pair, amount0Out, amount1Out, to, packedData) = ptr.decodeSwapUniV2();

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

    function decodeTransferERC20(
        bytes calldata encoded
    ) public pure returns (bool canFail, ERC20 token, address receiver, uint256 amount) {
        Ptr ptr;

        // add 0x01 bc the first byte is the `Action` opcode, it's not decoded
        assembly {
            ptr := add(0x01, encoded.offset)
        }

        (, canFail, token, receiver, amount) = ptr.decodeTransferERC20();
    }
}
