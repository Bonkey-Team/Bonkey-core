pragma solidity =0.5.16;

import './interfaces/IBEP20.sol';
import './interfaces/IProject.sol'

contract Project is IProject {
    address  _manager;
    address _source_token;
    address _target_token;
    uint _price;
    uint _min_rate_to_withdraw;
    uint _commission_rate;
    uint _num_proposals;
    uint _tot_vote_power;
    string _project_meta;
    mapping (address => uint) public _source_contributions;
    mapping (address => uint) public _target_contributions;
    mapping (uint => string) public _proposal_meta;
    mapping (uint => string) public _approval_meta;
    mapping (uint => uint) public _proposal_amount;


    // core logics
    function initiate(address source_token,
                      address target_token,
                      uint price,
                      uint min_rate_to_withdraw,
                      uint commission_rate,
                      string project_meta) external {
        _manager = msg.sender;
        _source_token = source_token;
        _target_token = target_token;
        _price = price;
        _min_rate_to_withdraw = min_rate_to_withdraw;
        _commission_rate = commission_rate;
        _project_meta = project_meta;
    } 


    function deposit(address token,
                     uint amount) external {
        require(token == _source_token || token == _target_token);
        IBEP20(token).transferFrom(msg.sender, this, amount);
        if(token == _source_token) {
            _source_contributions[msg.sender] += amount; 
        } else {
            _target_contributions[msg.sender] += amount; 
        }
        // update vote power
    }


    function propose(string propose_meta,
                     uint amount_target_token) external {
        require(msg.sender == _manager);
        _proposal_meta[_num_proposals] = propose_meta;
        _proposal_amount[_num_proposals] = amount_target_token;
        _num_proposals += 1;
    }


    function approve_proposal(uint index,
                              string approval_meta) external {
        _approval_meta[index] = approval_meta;
        
    }


    function reject_proposal(uint index,
                             string reject_meta) external pure;
    function withdraw(uint index,
                      string withdraw_meta) external pure;
    function approve_withdraw(uint index,
                              string approve_meta) external pure;
    function reject_withdraw(uint index,
                             string reject_meta) external pure;
    // read / list logics
    function get_project_info() external view returns (uint, uint, uint, string);
    function get_stake_holders() external view returns (address[]);
    function get_stake_holder_info(address) external view returns (uint, uint);
    function get_num_proposals() external view returns (uint);
    function get_proposal_info(uint index) external view returns (string, string[], string[]);
    function get_num_withdraws() external view returns (uint);
    function get_withdraw_info(uint index, uint index) external view returns (string, string[], string[]);

}
