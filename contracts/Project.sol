pragma solidity =0.5.16;

import './interfaces/IBEP20.sol';
import './interfaces/IProject.sol';
import './libraries/SafeMath.sol';

contract Project is IProject {

    using SafeMath for uint256; 
    
    struct Proposal {
        string                       _proposal_meta;
        uint256                      _proposed_amount;
        bool                         _approved;
        bool                         _rejected;
        bool                         _released;
        mapping (address => bool)    _proposal_approvals;
        mapping (address => bool)    _proposal_rejections;
        mapping (address => uint256) _approved_vote_power;
        mapping (address => uint256) _rejected_vote_power;
        mapping (address => string)  _approval_meta;
        mapping (address => string)  _reject_meta;
        uint256                      _tot_approved_vote_power;
        uint256                      _tot_rejected_vote_power;
        uint256                      _tot_vote_power_at_termination;

        uint256                      _num_payment_requests;
        mapping (uint => PaymentRequest) _payment_requests;
    }

    struct StakeHolder {
        uint256 _source_contribution;
        uint256 _target_contribution;
    }

    struct PaymentRequest {
        string                       _payment_request_meta;
        bool                         _approved;
        bool                         _rejected;
        mapping (address => bool)    _request_approvals;
        mapping (address => bool)    _request_rejections;
        mapping (address => uint256) _approved_vote_power;
        mapping (address => uint256) _rejected_vote_power;
        mapping (address => string)  _approval_meta;
        mapping (address => string)  _reject_meta;
        uint256                      _tot_approved_vote_power;
        uint256                      _tot_rejected_vote_power;
        uint256                      _tot_vote_power_at_termination;
    }

    address public                          _manager;
    address public                          _source_token;
    address public                          _target_token;
    uint256 public                          _price;
    uint256 public                          _min_rate_to_pass_proposal;
    uint256 public                          _min_rate_to_withdraw;
    uint256 public                          _commission_rate;
    uint256 public                          _tot_source_contribution;
    uint256 public                          _tot_target_contribution;
    string  public                          _project_meta;
    mapping (address => StakeHolder) public _stake_holders;

    uint256 public                          _num_proposals;
    mapping (uint => Proposal) public       _proposals;


    // core logics
    function initiate(address source_token,
                      address target_token,
                      uint256 price,
                      uint256 min_rate_to_pass_proposal,
                      uint256 min_rate_to_withdraw,
                      uint256 commission_rate,
                      string  calldata project_meta) external {
        require(_manager == address(0x0), "Project already initiated.");
        _manager                   = msg.sender;
        _source_token              = source_token;
        _target_token              = target_token;
        _price                     = price;
        _min_rate_to_pass_proposal = min_rate_to_pass_proposal;
        _min_rate_to_withdraw      = min_rate_to_withdraw;
        _commission_rate           = commission_rate;
        _project_meta              = project_meta;
    }


    function deposit(address token,
                     uint256 amount) external {
        require(token == _source_token || token == _target_token, "token unrecognized");
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        StakeHolder storage stake_holder = _stake_holders[msg.sender];
        if(token == _source_token) {
            stake_holder._source_contribution = stake_holder._source_contribution.add(amount); 
            _tot_source_contribution          = _tot_source_contribution.add(amount);
            
        } else {
            require(amount.mul(_price).add(_tot_target_contribution.mul(_price)) <= _tot_source_contribution,
                    "can not invest more than source token value");
            stake_holder._target_contribution = stake_holder._target_contribution.add(amount); 
            _tot_target_contribution          = _tot_target_contribution.add(amount);
        }
    }


    // TODO check locked fund
    function propose(string  calldata proposal_meta,
                     uint256 amount_target_token) external {
        require(msg.sender == _manager, "only manager can propose"); // TODO anyone can propose
        require(amount_target_token <= _tot_target_contribution);
        Proposal storage proposal = _proposals[_num_proposals];
        proposal._proposal_meta   = proposal_meta;
        proposal._proposed_amount = amount_target_token;
        _num_proposals = _num_proposals.add(1);
    }


    function is_proposal_approved(uint index) private view returns(bool) {
        // copmute total voting power
        Proposal storage proposal   = _proposals[index];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_approved_vote_power = proposal._tot_approved_vote_power;
        if(tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_proposal) {
            return true;
        }
        return false;
    }


    function make_proposal_approved(uint index) private {
        Proposal storage proposal = _proposals[index];
        proposal._approved        = true;
        proposal._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price)); 
        // TODO lock fund
    }


    function get_vote_power(address approver) private view returns(uint256) {
        StakeHolder storage stake_holder = _stake_holders[approver];
        uint256 vote_power = stake_holder._source_contribution; 
        vote_power = vote_power.add(stake_holder._target_contribution.mul(_price));
        return vote_power;
    }


    modifier can_vote_proposal(uint index) {
        require(index < _num_proposals, "vote for an unexisted proposal");
        Proposal storage proposal = _proposals[index];
        require(proposal._approved == false && proposal._rejected == false);
        require(proposal._proposal_approvals[msg.sender] == false);
        require(proposal._proposal_rejections[msg.sender] == false);
        _;
    }


    function approve_proposal(uint256          index,
                              string  calldata approval_meta) external can_vote_proposal(index) {
        Proposal storage proposal = _proposals[index];
        proposal._proposal_approvals[msg.sender]  = true;
        proposal._approval_meta[msg.sender]       = approval_meta;
        uint256 vote_power                        = get_vote_power(msg.sender);
        proposal._approved_vote_power[msg.sender] = vote_power;
        proposal._tot_approved_vote_power         = proposal._tot_approved_vote_power.add(vote_power); 

        if(is_proposal_approved(index) == true) {
            make_proposal_approved(index);
        }
    }


    function make_proposal_rejected(uint index) private {
        Proposal storage proposal = _proposals[index];
        proposal._rejected        = true;
        proposal._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price)); 
    }


    function reject_proposal(uint            index,
                             string calldata reject_meta) external can_vote_proposal(index) {
        Proposal storage proposal = _proposals[index];
        proposal._proposal_rejections[msg.sender] = true;
        proposal._reject_meta[msg.sender]         = reject_meta;
        uint256 vote_power                        = get_vote_power(msg.sender);
        proposal._rejected_vote_power[msg.sender] = vote_power;
        proposal._tot_rejected_vote_power         = proposal._tot_rejected_vote_power.add(vote_power); 

        if(is_proposal_approved(index) == true) {
            make_proposal_rejected(index);
        }
    }


    function is_request_approved(uint index, uint idx) private view returns(bool) {
        // copmute total voting power
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_approved_vote_power = request._tot_approved_vote_power;
        if(tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_proposal) {
            return true;
        }
        return false;
    }


    function make_request_approved(uint index, uint idx) private {
    }


    modifier can_request_payment(uint index) {
        require(index < _num_proposals);
        Proposal storage proposal = _proposals[index];
        require(proposal._approved == true);
        _;
    }


    function request_payment(uint            index,
                             uint            idx,
                             string calldata payment_meta) external can_request_payment(index) {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        request._payment_request_meta = payment_meta;
    }


    function approve_payment(uint            index,
                             uint            idx,
                             string calldata approval_meta) external {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        request._request_approvals[msg.sender]   = true;
        request._approval_meta[msg.sender]       = approval_meta;
        uint256 vote_power                       = get_vote_power(msg.sender);
        request._approved_vote_power[msg.sender] = vote_power;
        request._tot_approved_vote_power         = request._tot_approved_vote_power.add(vote_power); 

        if(is_request_approved(index, idx) == true) {
            make_request_approved(index, idx);
        }
    }


    function reject_payment(uint            index,
                            uint            idx,
                            string calldata reject_meta) external {
    } 
}
