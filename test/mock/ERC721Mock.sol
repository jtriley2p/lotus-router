// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

contract ERC721Mock {
    event Transfer(address indexed sender, address indexed receiver, uint256 indexed tokenId);

    bool internal _shouldThrow = false;

    function setShouldThrow(
        bool shouldThrow
    ) public {
        _shouldThrow = shouldThrow;
    }

    function transferFrom(address sender, address receiver, uint256 tokenId) public {
        require(!_shouldThrow);

        emit Transfer(sender, receiver, tokenId);
    }
}
