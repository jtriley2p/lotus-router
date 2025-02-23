// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { IUniV2Callee } from "test/interfaces/IUniV2Callee.sol";

contract UniV2PairMock {
    bool internal _shouldDoCallback = false;

    function setDoCallback(
        bool shouldDoCallback
    ) public {
        _shouldDoCallback = shouldDoCallback;
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) public {
        if (_shouldDoCallback && data.length > 0) {
            IUniV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        }
    }
}
