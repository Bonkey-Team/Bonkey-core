// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC165.sol";

contract SupportsInterface is
  ERC165
{

  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }


  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}
