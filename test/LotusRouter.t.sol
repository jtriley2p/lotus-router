// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Test } from "lib/forge-std/src/Test.sol";
import { UniV2PairMock } from "test/mock/UniV2PairMock.sol";

import { LotusRouter } from "src/LotusRouter.sol";
import { BBCEncoder } from "src/util/BBCEncoder.sol";

function takeAction(LotusRouter lotus, bytes memory data) returns (bool success) {
    bytes memory payload = abi.encodePacked(uint32(0x19ff8034), data);

    (success,) = address(lotus).call(payload);
}

contract LotusRouterTest is Test {
    using { takeAction } for LotusRouter;

    LotusRouter lotus;
    UniV2PairMock univ2_0;

    function setUp() public {
        lotus = new LotusRouter();
        univ2_0 = new UniV2PairMock();
    }

    function testUniV2SwapSingle() public {
        bool canFail = false;
        uint256 amount0Out = 0x01;
        uint256 amount1Out = 0x02;
        address to = address(0xaaaa);
        bytes memory data = hex"bbbb";

        vm.expectCall(
            address(univ2_0), abi.encodeCall(UniV2PairMock.swap, (amount0Out, amount1Out, to, data))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeSwapUniV2(canFail, address(univ2_0), amount0Out, amount1Out, to, data)
        );

        assertTrue(success);
    }
}
