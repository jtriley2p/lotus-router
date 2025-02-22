// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

enum Action {
    Halt,
    UniV2SwapExactIn,
    UniV2SwapExactOut,
    UniV3SwapExactIn,
    UniV3SwapExactOut,
    UniV4SwapExactIn,
    UniV4SwapExactOut,
    ERC20Transfer,
    ERC20TransferFrom,
    ERC721TransferFrom,
    ERC6909Transfer,
    ERC6909TransferFrom,
    WrapWETH,
    UnwrapWETH
}
