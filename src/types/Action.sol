// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { BytesCalldata } from "src/types/BytesCalldata.sol";
import { Ptr } from "src/types/PayloadPointer.sol";
import { ERC20 } from "src/types/protocols/ERC20.sol";

import { ERC6909 } from "src/types/protocols/ERC6909.sol";
import { ERC721 } from "src/types/protocols/ERC721.sol";
import { UniV2Pair } from "src/types/protocols/UniV2Pair.sol";
import { WETH } from "src/types/protocols/WETH.sol";
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
    DepositWETH,
    WithdrawWETH
}

using { execute } for Action global;

function execute(Action action, Ptr ptr) returns (Ptr, bool success) {
    if (action == Action.Halt) {
        assembly {
            stop()
        }
    } else if (action == Action.SwapUniV2) {
        bool canFail;
        UniV2Pair pair;
        uint256 amount0Out;
        uint256 amount1Out;
        address to;
        BytesCalldata data;

        (ptr, canFail, pair, amount0Out, amount1Out, to, data) = BBCDecoder.decodeSwapUniV2(ptr);

        success = pair.swap(amount0Out, amount1Out, to, data) || canFail;
    } else if (action == Action.SwapUniV3) {
        revert("todo");
    } else if (action == Action.SwapUniV4) {
        revert("todo");
    } else if (action == Action.TransferERC20) {
        bool canFail;
        ERC20 token;
        address receiver;
        uint256 amount;

        (ptr, canFail, token, receiver, amount) = BBCDecoder.decodeTransferERC20(ptr);

        success = token.transfer(receiver, amount) || canFail;
    } else if (action == Action.TransferFromERC20) {
        bool canFail;
        ERC20 token;
        address sender;
        address receiver;
        uint256 amount;

        (ptr, canFail, token, sender, receiver, amount) = BBCDecoder.decodeTransferFromERC20(ptr);

        success = token.transferFrom(sender, receiver, amount) || canFail;
    } else if (action == Action.TransferFromERC721) {
        bool canFail;
        ERC721 token;
        address sender;
        address receiver;
        uint256 amount;

        (ptr, canFail, token, sender, receiver, amount) = BBCDecoder.decodeTransferFromERC721(ptr);

        success = token.transferFrom(sender, receiver, amount) || canFail;
    } else if (action == Action.TransferERC6909) {
        bool canFail;
        ERC6909 multitoken;
        address receiver;
        uint256 tokenId;
        uint256 amount;

        (ptr, canFail, multitoken, receiver, tokenId, amount) =
            BBCDecoder.decodeTransferERC6909(ptr);

        success = multitoken.transfer(receiver, tokenId, amount) || canFail;
    } else if (action == Action.TransferFromERC6909) {
        revert("todo");
    } else if (action == Action.DepositWETH) {
        bool canFail;
        WETH weth;
        uint256 value;

        (ptr, canFail, weth, value) = BBCDecoder.decodeDepositWETH(ptr);

        success = weth.deposit(value) || canFail;
    } else if (action == Action.WithdrawWETH) {
        bool canFail;
        WETH weth;
        uint256 value;

        (ptr, canFail, weth, value) = BBCDecoder.decodeWithdrawWETH(ptr);

        success = weth.withdraw(value) || canFail;
    } else {
        success = false;
    }

    return (ptr, success);
}
