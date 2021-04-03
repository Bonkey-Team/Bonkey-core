// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


import './interfaces/IPersonalInfo.sol';


contract PersonalInfo is IPersonalInfo {

    address public              _manager;
    string private              _personal_meta;
    mapping (address => uint)   _whitelists;
    mapping (address => string) _memo;


    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }


    function create_personal_info(address manager,
                                  string  calldata meta) external override {
        require(_manager == address(0x0), 'can only initiate once');
        require(msg.sender == manager, 'you are not allowed to initiate');
        _manager = manager;
        _personal_meta = meta;
    }


    function allow_access(address person,
                          uint    expire_block,
                          string  calldata memo) external override {
        require(msg.sender == _manager, 'you are not allowed to set whitelist');
        _whitelists[person] = expire_block;
        _memo[person] = memo;
    }


    function get_personal_info() external 
                                 view 
                                 override 
                                 returns(string memory meta) {
        uint expire_block = _whitelists[msg.sender];
        require((expire_block > getBlockNumber()) ||
                (msg.sender == _manager), 
                 'You are not allowed to access the data!');
        meta = _personal_meta;
        return meta;
    }
}
