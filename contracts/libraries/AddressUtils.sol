// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library AddressUtils
{

  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

