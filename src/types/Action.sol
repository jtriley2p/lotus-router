// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { BBCDecoder } from "src/util/BBCDecoder.sol";

enum Action {
    Halt,
    SwapUniV2,
    SwapUniV3,
    SwapUniV4,
    TransferERC20,
    TransferFromERC20,
    TransferFromERC721,
    TransferERC6909,
    TransferFromERC6909,
    WrapWETH,
    UnwrapWETH
}

using { execute } for Action global;

function execute(Action action, Ptr ptr) returns (Ptr, bool success) {
    if (action == Action.SwapUniV2) {
        bool canFail;
        UniV2Pair pair;
        uint256 amount0Out;
        uint256 amount1Out;
        address to;
        BytesCalldata data;

        (ptr, canFail, pair, amount0Out, amount1Out, to, data) = BBCDecoder.decodeSwapUniV2(ptr);

        success = pair.swap(amount0Out, amount1Out, to, data) || canFail;
    } else {
        success = false;
    }

    return (ptr, success);
}
