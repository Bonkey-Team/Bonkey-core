// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import '../interfaces/IERC165.sol';
import './Initializable.sol';

abstract contract ERC165 is IERC165, Initializable {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function __ERC165_init_unchained() internal initializer {
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
