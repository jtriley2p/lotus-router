// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

contract ERC20Mock {
    event Transfer(address indexed sender, address indexed receiver, uint256 amount);

    bool internal _shouldThrow = false;
    bool internal _shouldReturnAnything = true;
    bool internal _result = true;

    function setShouldThrow(
        bool shouldThrow
    ) public {
        _shouldThrow = shouldThrow;
    }

    function setShouldReturnAnything(
        bool shouldReturnAnything
    ) public {
        _shouldReturnAnything = shouldReturnAnything;
    }

    function setResult(
        bool result
    ) public {
        _result = result;
    }

    function transfer(address receiver, uint256 amount) public returns (bool) {
        require(!_shouldThrow);

        emit Transfer(msg.sender, receiver, amount);

        if (_shouldReturnAnything) return _result;

        assembly {
            return(0x00, 0x00)
        }
    }

    function transferFrom(address sender, address receiver, uint256 amount) public returns (bool) {
        require(!_shouldThrow);

        emit Transfer(sender, receiver, amount);

        if (_shouldReturnAnything) return _result;

        assembly {
            return(0x00, 0x00)
        }
    }
}
