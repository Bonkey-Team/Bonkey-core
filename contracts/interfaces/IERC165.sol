// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC165
{

  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}
