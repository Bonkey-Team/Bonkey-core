// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IRandom {
    function generate_random(uint256 base, address sender) external returns(uint256);
}
