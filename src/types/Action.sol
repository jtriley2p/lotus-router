// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { BBCDecoder } from "src/util/BBCDecoder.sol";

enum Action {
    Halt,
    UniV2Swap,
    UniV3Swap,
    UniV4Swap,
    ERC20Transfer,
    ERC20TransferFrom,
    ERC721TransferFrom,
    ERC6909Transfer,
    ERC6909TransferFrom,
    WrapWETH,
    UnwrapWETH
}

using { execute } for Action global;

function execute(Action action, Ptr ptr) returns (Ptr, bool success) {
    if (action == Action.UniV2Swap) {
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
