// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

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
    UniV2PairMock univ2_1;

    function setUp() public {
        lotus = new LotusRouter();
        univ2_0 = new UniV2PairMock();
        univ2_1 = new UniV2PairMock();
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

    function testUniV2SwapChain() public {
        bool canFail = false;

        uint256 amount0Out_0 = 0x01;
        uint256 amount1Out_0 = 0x02;
        address to_0 = address(0xaaaa);
        bytes memory data_0 = hex"bbbb";

        uint256 amount0Out_1 = 0x03;
        uint256 amount1Out_1 = 0x04;
        address to_1 = address(0xcccc);
        bytes memory data_1 = hex"dddd";

        vm.expectCall(
            address(univ2_0),
            abi.encodeCall(UniV2PairMock.swap, (amount0Out_0, amount1Out_0, to_0, data_0))
        );

        vm.expectCall(
            address(univ2_1),
            abi.encodeCall(UniV2PairMock.swap, (amount0Out_1, amount1Out_1, to_1, data_1))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeSwapUniV2(
                    canFail, address(univ2_0), amount0Out_0, amount1Out_0, to_0, data_0
                ),
                BBCEncoder.encodeSwapUniV2(
                    canFail, address(univ2_1), amount0Out_1, amount1Out_1, to_1, data_1
                )
            )
        );

        assertTrue(success);
    }

    function testUniv2SwapSingleThrows() public {
        bool canFail = false;
        uint256 amount0Out = 0x01;
        uint256 amount1Out = 0x02;
        address to = address(0xaaaa);
        bytes memory data = hex"bbbb";

        univ2_0.setShouldThrow(true);

        bool success = lotus.takeAction(
            BBCEncoder.encodeSwapUniV2(canFail, address(univ2_0), amount0Out, amount1Out, to, data)
        );

        assertFalse(success);
    }

    function testUniV2SwapChainThrows() public {
        bool canFail = false;

        uint256 amount0Out_0 = 0x01;
        uint256 amount1Out_0 = 0x02;
        address to_0 = address(0xaaaa);
        bytes memory data_0 = hex"bbbb";

        uint256 amount0Out_1 = 0x03;
        uint256 amount1Out_1 = 0x04;
        address to_1 = address(0xcccc);
        bytes memory data_1 = hex"dddd";

        univ2_0.setShouldThrow(true);

        // expect call `0` times, since the univ2_0 market failure should short
        // circuit this
        vm.expectCall(
            address(univ2_1),
            abi.encodeCall(UniV2PairMock.swap, (amount0Out_1, amount1Out_1, to_1, data_1)),
            0
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeSwapUniV2(
                    canFail, address(univ2_0), amount0Out_0, amount1Out_0, to_0, data_0
                ),
                BBCEncoder.encodeSwapUniV2(
                    canFail, address(univ2_1), amount0Out_1, amount1Out_1, to_1, data_1
                )
            )
        );

        assertFalse(success);
    }

    function testFuzzUniV2SwapSingle(
        bool canFail,
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) public {
        vm.expectCall(
            address(univ2_0), abi.encodeCall(UniV2PairMock.swap, (amount0Out, amount1Out, to, data))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeSwapUniV2(canFail, address(univ2_0), amount0Out, amount1Out, to, data)
        );

        assertTrue(success || canFail);
    }

    function testFuzzUniV2SwapChain(
        uint256 amount0Out_0,
        uint256 amount1Out_0,
        bytes memory data_0,
        uint256 amount0Out_1,
        uint256 amount1Out_1,
        bytes memory data_1
    ) public {
        // smth's up w the fuzzer; vm.expectCall fails, vm.expectEmit does not..
        // all data's the same tho?
        vm.expectEmit(true, true, true, true, address(univ2_0));
        emit UniV2PairMock.Swap(amount0Out_0, amount1Out_0, address(univ2_1), data_0);

        vm.expectEmit(true, true, true, true, address(univ2_1));
        emit UniV2PairMock.Swap(amount0Out_1, amount1Out_1, address(lotus), data_1);

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeSwapUniV2(
                    false, address(univ2_0), amount0Out_0, amount1Out_0, address(univ2_1), data_0
                ),
                BBCEncoder.encodeSwapUniV2(
                    false, address(univ2_1), amount0Out_1, amount1Out_1, address(lotus), data_1
                )
            )
        );

        assertTrue(success);
    }
}
