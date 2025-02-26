// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

contract ERC6909Mock {
    event Transfer(
        address caller, address sender, address receiver, uint256 tokenId, uint256 amount
    );

    bool internal _shouldThrow = false;
    bool internal _result = true;

    function setShouldThrow(
        bool shouldThrow
    ) public {
        _shouldThrow = shouldThrow;
    }

    function setResult(
        bool result
    ) public {
        _result = result;
    }

    function transfer(address receiver, uint256 tokenId, uint256 amount) public returns (bool) {
        require(!_shouldThrow);

        emit Transfer(msg.sender, msg.sender, receiver, tokenId, amount);

        return _result;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    ) public returns (bool) {
        require(!_shouldThrow);

        emit Transfer(msg.sender, sender, receiver, tokenId, amount);

        return _result;
    }
}
