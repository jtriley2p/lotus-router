// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Test } from "lib/forge-std/src/Test.sol";
import { ERC20Mock } from "test/mock/ERC20Mock.sol";

import { ERC6909Mock } from "test/mock/ERC6909Mock.sol";
import { ERC721Mock } from "test/mock/ERC721Mock.sol";
import { UniV2PairMock } from "test/mock/UniV2PairMock.sol";
import { WETHMock, wethBytecode } from "test/mock/WETHMock.sol";

import { LotusRouter } from "src/LotusRouter.sol";
import { BBCEncoder } from "src/util/BBCEncoder.sol";

function takeAction(LotusRouter lotus, bytes memory data) returns (bool success) {
    bytes memory payload = abi.encodePacked(uint32(0x19ff8034), data);

    (success,) = address(lotus).call(payload);
}

function takeActionWithValue(
    LotusRouter lotus,
    uint256 value,
    bytes memory data
) returns (bool success) {
    bytes memory payload = abi.encodePacked(uint32(0x19ff8034), data);

    (success,) = address(lotus).call{ value: value }(payload);
}

contract LotusRouterTest is Test {
    using { takeAction, takeActionWithValue } for LotusRouter;

    LotusRouter lotus;
    UniV2PairMock univ2_0;
    UniV2PairMock univ2_1;
    ERC20Mock erc20_0;
    ERC20Mock erc20_1;
    ERC721Mock erc721_0;
    ERC721Mock erc721_1;
    ERC6909Mock erc6909_0;
    ERC6909Mock erc6909_1;
    WETHMock weth;

    function setUp() public {
        lotus = new LotusRouter();
        univ2_0 = new UniV2PairMock();
        univ2_1 = new UniV2PairMock();
        erc20_0 = new ERC20Mock();
        erc20_1 = new ERC20Mock();
        erc721_0 = new ERC721Mock();
        erc721_1 = new ERC721Mock();
        erc6909_0 = new ERC6909Mock();
        erc6909_1 = new ERC6909Mock();
        weth = new WETHMock();
    }

    // -- UNIV2 ------------------------------------------------------------------------------------

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

    // -- ERC20 ------------------------------------------------------------------------------------

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

    // -- ERC721 -----------------------------------------------------------------------------------

    function testTransferFromERC721Single() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 tokenId = 0x02;

        vm.expectCall(
            address(erc721_0), abi.encodeCall(ERC721Mock.transferFrom, (sender, receiver, tokenId))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC721(
                canFail, address(erc721_0), sender, receiver, tokenId
            )
        );

        assertTrue(success);
    }

    function testTransferFromERC721SingleThrows() public {
        bool canFail = false;
        address sender = address(0xaabbccdd);
        address receiver = address(0xeeffaabb);
        uint256 tokenId = 0x02;

        erc721_0.setShouldThrow(true);

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC721(
                canFail, address(erc721_0), sender, receiver, tokenId
            )
        );

        assertFalse(success);
    }

    function testFuzzTransferFromERC721Single(
        bool canFail,
        bool shouldThrow,
        address sender,
        address receiver,
        uint256 tokenId
    ) public {
        erc721_0.setShouldThrow(shouldThrow);

        if (!shouldThrow || canFail) {
            vm.expectCall(
                address(erc721_0),
                abi.encodeCall(ERC721Mock.transferFrom, (sender, receiver, tokenId))
            );
        }

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferFromERC721(
                canFail, address(erc721_0), sender, receiver, tokenId
            )
        );

        assertEq(success, !shouldThrow || canFail);
    }

    function testTransferFromERC721Chain() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 tokenId_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 tokenId_1 = 0x04;

        vm.expectCall(
            address(erc721_0),
            abi.encodeCall(ERC721Mock.transferFrom, (sender_0, receiver_0, tokenId_0))
        );

        vm.expectCall(
            address(erc721_1),
            abi.encodeCall(ERC721Mock.transferFrom, (sender_1, receiver_1, tokenId_1))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_0), sender_0, receiver_0, tokenId_0
                ),
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_1), sender_1, receiver_1, tokenId_1
                )
            )
        );

        assertTrue(success);
    }

    function testTransferFromERC721ChainFirstThrows() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 tokenId_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 tokenId_1 = 0x04;

        erc721_0.setShouldThrow(true);

        vm.expectCall(
            address(erc721_1),
            abi.encodeCall(ERC721Mock.transferFrom, (sender_1, receiver_1, tokenId_1)),
            0
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_0), sender_0, receiver_0, tokenId_0
                ),
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_1), sender_1, receiver_1, tokenId_1
                )
            )
        );

        assertFalse(success);
    }

    function testTransferFromERC721ChainSecondThrows() public {
        bool canFail = false;

        address sender_0 = address(0xaabbccdd);
        address receiver_0 = address(0xeeffaabb);
        uint256 tokenId_0 = 0x02;

        address sender_1 = address(0xccddeeff);
        address receiver_1 = address(0xaabbccdd);
        uint256 tokenId_1 = 0x04;

        erc721_1.setShouldThrow(true);

        vm.expectCall(
            address(erc721_0),
            abi.encodeCall(ERC721Mock.transferFrom, (sender_0, receiver_0, tokenId_0))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_0), sender_0, receiver_0, tokenId_0
                ),
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_1), sender_1, receiver_1, tokenId_1
                )
            )
        );

        assertFalse(success);
    }

    function testFuzzTransferFromERC721Chain(
        bool canFail,
        bool shouldThrow,
        address sender,
        address receiver,
        uint256 tokenId
    ) public {
        erc721_0.setShouldThrow(shouldThrow);
        erc721_0.setShouldThrow(shouldThrow);

        if (!shouldThrow || canFail) {
            vm.expectCall(
                address(erc721_0),
                abi.encodeCall(ERC721Mock.transferFrom, (sender, receiver, tokenId))
            );

            vm.expectCall(
                address(erc721_1),
                abi.encodeCall(ERC721Mock.transferFrom, (sender, receiver, tokenId))
            );
        }

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_0), sender, receiver, tokenId
                ),
                BBCEncoder.encodeTransferFromERC721(
                    canFail, address(erc721_1), sender, receiver, tokenId
                )
            )
        );

        assertEq(success, !shouldThrow || canFail);
    }

    // -- ERC6909 ----------------------------------------------------------------------------------

    function testTransferERC6909Single() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 tokenId = 0x45;
        uint256 amount = 0x46;

        vm.expectCall(
            address(erc6909_0), abi.encodeCall(ERC6909Mock.transfer, (receiver, tokenId, amount))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC6909(canFail, address(erc6909_0), receiver, tokenId, amount)
        );

        assertTrue(success);
    }

    function testTransferERC6909SingleThrows() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 tokenId = 0x45;
        uint256 amount = 0x46;

        erc6909_0.setShouldThrow(true);

        vm.expectCall(
            address(erc6909_0), abi.encodeCall(ERC6909Mock.transfer, (receiver, tokenId, amount))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC6909(canFail, address(erc6909_0), receiver, tokenId, amount)
        );

        assertFalse(success);
    }

    function testTransferERC6909SingleReturnsFalse() public {
        bool canFail = false;
        address receiver = address(0xaabbccdd);
        uint256 tokenId = 0x45;
        uint256 amount = 0x46;

        erc6909_0.setResult(false);

        vm.expectCall(
            address(erc6909_0), abi.encodeCall(ERC6909Mock.transfer, (receiver, tokenId, amount))
        );

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC6909(canFail, address(erc6909_0), receiver, tokenId, amount)
        );

        assertFalse(success);
    }

    function testFuzzTransferERC6909Single(
        bool canFail,
        bool result,
        bool shouldThrow,
        address receiver,
        uint256 tokenId,
        uint256 amount
    ) public {
        erc6909_0.setResult(result);
        erc6909_0.setShouldThrow(shouldThrow);

        if (!shouldThrow && result || canFail) {
            vm.expectCall(
                address(erc6909_0),
                abi.encodeCall(ERC6909Mock.transfer, (receiver, tokenId, amount))
            );
        }

        bool success = lotus.takeAction(
            BBCEncoder.encodeTransferERC6909(canFail, address(erc6909_0), receiver, tokenId, amount)
        );

        assertEq(success, !shouldThrow && result || canFail);
    }

    function testTransferERC6909Chain() public {
        bool canFail = false;
        address receiver_0 = address(0xaabbccdd);
        uint256 tokenId_0 = 0x45;
        uint256 amount_0 = 0x46;

        address receiver_1 = address(0xeeffaabb);
        uint256 tokenId_1 = 0x47;
        uint256 amount_1 = 0x48;

        vm.expectCall(
            address(erc6909_0),
            abi.encodeCall(ERC6909Mock.transfer, (receiver_0, tokenId_0, amount_0))
        );

        vm.expectCall(
            address(erc6909_1),
            abi.encodeCall(ERC6909Mock.transfer, (receiver_1, tokenId_1, amount_1))
        );

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_0), receiver_0, tokenId_0, amount_0
                ),
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_1), receiver_1, tokenId_1, amount_1
                )
            )
        );

        assertTrue(success);
    }

    function testTransferERC6909ChainThrows() public {
        bool canFail = false;
        address receiver_0 = address(0xaabbccdd);
        uint256 tokenId_0 = 0x45;
        uint256 amount_0 = 0x46;

        address receiver_1 = address(0xeeffaabb);
        uint256 tokenId_1 = 0x47;
        uint256 amount_1 = 0x48;

        erc6909_0.setShouldThrow(true);

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_0), receiver_0, tokenId_0, amount_0
                ),
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_1), receiver_1, tokenId_1, amount_1
                )
            )
        );

        assertFalse(success);
    }

    function testTransferERC6909ChainReturnsFalse() public {
        bool canFail = false;
        address receiver_0 = address(0xaabbccdd);
        uint256 tokenId_0 = 0x45;
        uint256 amount_0 = 0x46;

        address receiver_1 = address(0xeeffaabb);
        uint256 tokenId_1 = 0x47;
        uint256 amount_1 = 0x48;

        erc6909_0.setResult(false);

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_0), receiver_0, tokenId_0, amount_0
                ),
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_1), receiver_1, tokenId_1, amount_1
                )
            )
        );

        assertFalse(success);
    }

    function testFuzzTransferERC6909Chain(
        bool canFail,
        bool result,
        bool shouldThrow,
        address receiver_0,
        uint256 tokenId_0,
        uint256 amount_0,
        address receiver_1,
        uint256 tokenId_1,
        uint256 amount_1
    ) public {
        erc6909_0.setResult(result);
        erc6909_0.setShouldThrow(shouldThrow);
        erc6909_1.setResult(result);
        erc6909_1.setShouldThrow(shouldThrow);

        if (!shouldThrow && result || canFail) {
            vm.expectCall(
                address(erc6909_0),
                abi.encodeCall(ERC6909Mock.transfer, (receiver_0, tokenId_0, amount_0))
            );

            vm.expectCall(
                address(erc6909_1),
                abi.encodeCall(ERC6909Mock.transfer, (receiver_1, tokenId_1, amount_1))
            );
        }

        bool success = lotus.takeAction(
            abi.encodePacked(
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_0), receiver_0, tokenId_0, amount_0
                ),
                BBCEncoder.encodeTransferERC6909(
                    canFail, address(erc6909_1), receiver_1, tokenId_1, amount_1
                )
            )
        );

        assertEq(success, !shouldThrow && result || canFail);
    }

    // -- WETH -------------------------------------------------------------------------------------

    function testDepositWETHNothing() public {
        bool canFail = false;
        uint256 value = 0x00;

        vm.expectCall(address(weth), value, new bytes(0));

        bool success = lotus.takeAction(BBCEncoder.encodeDepositWETH(canFail, address(weth), value));

        assertTrue(success);
    }

    function testDepositWETHFromCaller() public {
        bool canFail = false;
        uint256 value = 0x01;

        vm.expectCall(address(weth), value, new bytes(0));

        bool success = lotus.takeActionWithValue(
            value, BBCEncoder.encodeDepositWETH(canFail, address(weth), value)
        );

        assertTrue(success);
    }

    function testDepositWETHFromBalance() public {
        bool canFail = false;
        uint256 value = 0x01;

        vm.deal(address(lotus), value);

        vm.expectCall(address(weth), value, new bytes(0));

        bool success = lotus.takeAction(BBCEncoder.encodeDepositWETH(canFail, address(weth), value));

        assertTrue(success);
    }

    function testDepositWETHThrows() public {
        bool canFail = false;
        uint256 value = 0x00;

        weth.setShouldThrow(true);

        bool success = lotus.takeAction(BBCEncoder.encodeDepositWETH(canFail, address(weth), value));

        assertFalse(success);
    }

    function testFuzzDepositWETH(
        bool canFail,
        bool shouldThrow,
        bool fromCaller,
        uint256 value
    ) public {
        address alice = address(0xaaaaaaaa);
        vm.startPrank(alice);

        weth.setShouldThrow(shouldThrow);

        if (canFail || !shouldThrow) {
            vm.expectCall(address(weth), value, new bytes(0));
        }

        bool success;

        if (fromCaller) {
            vm.deal(alice, value);

            success = lotus.takeActionWithValue(
                value, BBCEncoder.encodeDepositWETH(canFail, address(weth), value)
            );
        } else {
            vm.deal(address(lotus), value);

            success = lotus.takeAction(BBCEncoder.encodeDepositWETH(canFail, address(weth), value));
        }

        assertEq(success, canFail || !shouldThrow);

        vm.stopPrank();
    }

    function testWithdrawWETH() public {
        bool canFail = false;
        uint256 value = 0x01;

        vm.expectCall(address(weth), abi.encodeCall(WETHMock.withdraw, (value)));

        bool success =
            lotus.takeAction(BBCEncoder.encodeWithdrawWETH(canFail, address(weth), value));

        assertTrue(success);
    }

    function testWithdrawWETHTHrows() public {
        bool canFail = false;
        uint256 value = 0x01;

        weth.setShouldThrow(true);

        bool success =
            lotus.takeAction(BBCEncoder.encodeWithdrawWETH(canFail, address(weth), value));

        assertFalse(success);
    }

    function testFuzzWithdrawWETH(bool canFail, bool shouldThrow, uint256 value) public {
        weth.setShouldThrow(shouldThrow);

        if (canFail || !shouldThrow) {
            vm.expectCall(address(weth), new bytes(0));
        }

        bool success =
            lotus.takeAction(BBCEncoder.encodeWithdrawWETH(canFail, address(weth), value));

        assertEq(success, canFail || !shouldThrow);
    }

    function testWETHSendIsCheaperThanDeposit() public {
        address alice = address(0xaaaaaa);
        address cannonWeth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint256 value = 0x02;
        uint256 gasDepositBefore;
        uint256 gasDepositAfter;
        uint256 gasSendBefore;
        uint256 gasSendAfter;

        vm.etch(cannonWeth, wethBytecode());
        vm.deal(alice, value * 5);
        vm.startPrank(alice);

        // call weth once to make sure the slot is warm
        assembly {
            pop(call(gas(), cannonWeth, value, 0x00, 0x00, 0x00, 0x00))
        }

        // call deposit then send
        assembly {
            // call weth.deposit()
            mstore(0x00, 0xd0e30db000000000000000000000000000000000000000000000000000000000)
            gasDepositBefore := gas()
            pop(call(gas(), cannonWeth, value, 0x00, 0x04, 0x00, 0x00))
            gasDepositAfter := gas()

            // send ether to weth (no calldata)
            gasSendBefore := gas()
            pop(call(gas(), cannonWeth, value, 0x00, 0x00, 0x00, 0x00))
            gasSendAfter := gas()
        }

        assertLt(gasSendBefore - gasSendAfter, gasDepositBefore - gasDepositAfter);

        // call send then deposit
        assembly {
            // send ether to weth (no calldata)
            gasSendBefore := gas()
            pop(call(gas(), cannonWeth, value, 0x00, 0x00, 0x00, 0x00))
            gasSendAfter := gas()

            // call weth.deposit()
            mstore(0x00, 0xd0e30db000000000000000000000000000000000000000000000000000000000)
            gasDepositBefore := gas()
            pop(call(gas(), cannonWeth, value, 0x00, 0x04, 0x00, 0x00))
            gasDepositAfter := gas()
        }

        assertLt(gasSendBefore - gasSendAfter, gasDepositBefore - gasDepositAfter);

        vm.stopPrank();
    }
}
