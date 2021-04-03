// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


interface IPersonalInfo {
    event AllowInfo(address indexed token0, uint); // allow whom, and the block time
    event DisallowInfo(address indexed token0, uint);


    function create_personal_info(address manager,
                                  string  calldata meta) external;

    function allow_access(address person,
                          uint    expire_block,
                          string  calldata memo) external;

    function get_personal_info() external view returns(string memory meta);
}
