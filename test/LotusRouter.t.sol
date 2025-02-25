// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Test } from "lib/forge-std/src/Test.sol";

import { ERC20Mock } from "test/mock/ERC20Mock.sol";
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
    ERC20Mock erc20_0;
    ERC20Mock erc20_1;

    function setUp() public {
        lotus = new LotusRouter();
        univ2_0 = new UniV2PairMock();
        univ2_1 = new UniV2PairMock();
        erc20_0 = new ERC20Mock();
        erc20_1 = new ERC20Mock();
    }

    function testSwapUniV2Single() public {
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

    function testSwapUniV2SingleThrows() public {
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

    function testFuzzSwapUniV2Single(
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

    function testSwapUniV2Chain() public {
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

    function testSwapUniV2ChainThrows() public {
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

    function testFuzzSwapUniV2Chain(
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

    function testTransferERC20Single() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 amount = 0x02;

        vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver, amount)));

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount)
        );

        assertTrue(success);
    }

    function testTransferERC20SingleReturnsNothing() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 amount = 0x02;

        erc20_0.setShouldReturnAnything(false);

        vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver, amount)));

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount)
        );

        assertTrue(success);
    }

    function testTransferERC20SingleThrows() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 amount = 0x02;

        erc20_0.setShouldThrow(true);

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount)
        );

        assertFalse(success);
    }

    function testTransferERC20SingleReturnsFalse() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 amount = 0x02;

        erc20_0.setResult(false);

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount)
        );

        assertFalse(success);
    }

    function testFuzzTransferERC20Single(
        bool canFail,
        bool shouldReturnAnything,
        bool shouldThrow,
        bool result,
        address receiver,
        uint256 amount
    ) public {
        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        bool callSucceeds = !shouldThrow && (result || !shouldReturnAnything) || canFail;

        if (callSucceeds) {
            vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver, amount)));
        }

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount)
        );

        assertEq(success, callSucceeds);
    }

    function testTransferERC20Chain() public {
        bool canFail = false;

        address receiver_0 = address(0xaabbccdd);
        uint256 amount_0 = 0x02;

        address receiver_1 = address(0xeeffaabb);
        uint256 amount_1 = 0x04;

        vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver_0, amount_0)));

        vm.expectCall(address(erc20_1), abi.encodeCall(ERC20Mock.transfer, (receiver_1, amount_1)));

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver_0, amount_0),
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_1), receiver_1, amount_1)
            )
        );

        assertTrue(success);
    }

    function testTransferERC20ChainReturnsNothing() public {
        bool canFail = false;

        address receiver_0 = address(0xaabbccdd);
        uint256 amount_0 = 0x02;

        address receiver_1 = address(0xeeffaabb);
        uint256 amount_1 = 0x04;

        erc20_0.setShouldReturnAnything(false);
        erc20_1.setShouldReturnAnything(false);

        vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver_0, amount_0)));

        vm.expectCall(address(erc20_1), abi.encodeCall(ERC20Mock.transfer, (receiver_1, amount_1)));

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver_0, amount_0),
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_1), receiver_1, amount_1)
            )
        );

        assertTrue(success);
    }

    function testTransferERC20ChainFirstThrows() public {
        bool canFail = false;

        address receiver_0 = address(0xaabbccdd);
        uint256 amount_0 = 0x02;

        address receiver_1 = address(0xeeffaabb);
        uint256 amount_1 = 0x04;

        erc20_0.setShouldThrow(true);

        vm.expectCall(
            address(erc20_1), abi.encodeCall(ERC20Mock.transfer, (receiver_1, amount_1)), 0
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver_0, amount_0),
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_1), receiver_1, amount_1)
            )
        );

        assertFalse(success);
    }

    function testTransferERC20ChainSecondThrows() public {
        bool canFail = false;

        address receiver_0 = address(0xaabbccdd);
        uint256 amount_0 = 0x02;

        address receiver_1 = address(0xeeffaabb);
        uint256 amount_1 = 0x04;

        erc20_1.setShouldThrow(true);

        vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver_0, amount_0)));

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver_0, amount_0),
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_1), receiver_1, amount_1)
            )
        );

        assertFalse(success);
    }

    function testFuzzTransferERC20Chain(
        bool canFail,
        bool shouldReturnAnything,
        bool shouldThrow,
        bool result,
        address receiver,
        uint256 amount
    ) public {
        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        bool callSucceeds = !shouldThrow && (result || !shouldReturnAnything) || canFail;

        if (callSucceeds) {
            vm.expectCall(address(erc20_0), abi.encodeCall(ERC20Mock.transfer, (receiver, amount)));

            vm.expectCall(address(erc20_1), abi.encodeCall(ERC20Mock.transfer, (receiver, amount)));
        }

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_0), receiver, amount),
                BBCEncoder.encodeTransferERC20(canFail, address(erc20_1), receiver, amount)
            )
        );

        assertEq(success, callSucceeds);
    }

    function testTransferFromERC20Single() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 amount = 0x02;

        vm.expectCall(
            address(erc20_0), abi.encodeCall(ERC20Mock.transferFrom, (sender, receiver, amount))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC20(canFail, address(erc20_0), sender, receiver, amount)
        );

        assertTrue(success);
    }

    function testTransferFromERC20SingleReturnsNothing() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 amount = 0x02;

        erc20_0.setShouldReturnAnything(false);

        vm.expectCall(
            address(erc20_0), abi.encodeCall(ERC20Mock.transferFrom, (sender, receiver, amount))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC20(canFail, address(erc20_0), sender, receiver, amount)
        );

        assertTrue(success);
    }

    function testTransferFromERC20SingleThrows() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 amount = 0x02;

        erc20_0.setShouldThrow(true);

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC20(canFail, address(erc20_0), sender, receiver, amount)
        );

        assertFalse(success);
    }

    function testTransferFromERC20SingleReturnsFalse() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 amount = 0x02;

        erc20_0.setResult(false);

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC20(canFail, address(erc20_0), sender, receiver, amount)
        );

        assertFalse(success);
    }

    function testFuzzTransferFromERC20Single(
        bool canFail,
        bool shouldReturnAnything,
        bool shouldThrow,
        bool result,
        address sender,
        address receiver,
        uint256 amount
    ) public {
        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        bool callSucceeds = (!shouldThrow && (result || !shouldReturnAnything)) || canFail;

        if (callSucceeds) {
            vm.expectCall(
                address(erc20_0), abi.encodeCall(ERC20Mock.transferFrom, (sender, receiver, amount))
            );
        }

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC20(canFail, address(erc20_0), sender, receiver, amount)
        );

        assertEq(success, callSucceeds);
    }

    function testTransferFromERC20Chain() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 amount_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 amount_1 = 0x04;

        vm.expectCall(
            address(erc20_0),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_0, receiver_0, amount_0))
        );

        vm.expectCall(
            address(erc20_1),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_1, receiver_1, amount_1))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_0), sender_0, receiver_0, amount_0
                ),
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_1), sender_1, receiver_1, amount_1
                )
            )
        );

        assertTrue(success);
    }

    function testTransferFromERC20ChainReturnsNothing() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 amount_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 amount_1 = 0x04;

        erc20_0.setShouldReturnAnything(false);
        erc20_1.setShouldReturnAnything(false);

        vm.expectCall(
            address(erc20_0),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_0, receiver_0, amount_0))
        );

        vm.expectCall(
            address(erc20_1),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_1, receiver_1, amount_1))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_0), sender_0, receiver_0, amount_0
                ),
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_1), sender_1, receiver_1, amount_1
                )
            )
        );

        assertTrue(success);
    }

    function testTransferFromERC20ChainFirstThrows() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 amount_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 amount_1 = 0x04;

        erc20_0.setShouldThrow(true);

        vm.expectCall(
            address(erc20_1),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_1, receiver_1, amount_1)),
            0
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_0), sender_0, receiver_0, amount_0
                ),
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_1), sender_1, receiver_1, amount_1
                )
            )
        );

        assertFalse(success);
    }

    function testTransferFromERC20ChainSecondThrows() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 amount_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 amount_1 = 0x04;

        erc20_1.setShouldThrow(true);

        vm.expectCall(
            address(erc20_0),
            abi.encodeCall(ERC20Mock.transferFrom, (sender_0, receiver_0, amount_0))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_0), sender_0, receiver_0, amount_0
                ),
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_1), sender_1, receiver_1, amount_1
                )
            )
        );

        assertFalse(success);
    }

    function testFuzzTransferFromERC20Chain(
        bool canFail,
        bool shouldReturnAnything,
        bool shouldThrow,
        bool result,
        address sender,
        address receiver,
        uint256 amount
    ) public {
        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        erc20_0.setShouldReturnAnything(shouldReturnAnything);
        erc20_0.setShouldThrow(shouldThrow);
        erc20_0.setResult(result);

        bool callSucceeds = !shouldThrow && (result || !shouldReturnAnything) || canFail;

        if (callSucceeds) {
            vm.expectCall(
                address(erc20_0), abi.encodeCall(ERC20Mock.transferFrom, (sender, receiver, amount))
            );

            vm.expectCall(
                address(erc20_1), abi.encodeCall(ERC20Mock.transferFrom, (sender, receiver, amount))
            );
        }

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_0), sender, receiver, amount
                ),
                BBCEncoder.encodeTransferFromERC20(
                    canFail, address(erc20_1), sender, receiver, amount
                )
            )
        );

        assertEq(success, callSucceeds);
    }
}
