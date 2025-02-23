// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

interface IUniV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
