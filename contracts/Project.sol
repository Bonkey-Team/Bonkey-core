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
        uint256                      _deadline;

        uint256                      _num_payment_requests;
        mapping (uint => PaymentRequest) _payment_requests;
    }

    struct StakeHolder {
        uint256 _source_contribution;
        uint256 _target_contribution;
    }

    struct PaymentRequest {
        address                      _contributor;
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
        uint256                      _deadline;
    }

    address public                          _manager;
    address public                          _source_token;
    address public                          _target_token;
    uint256 public                          _price;
    uint256 public                          _min_rate_to_pass_proposal;
    uint256 public                          _min_rate_to_pass_request;
    uint256 public                          _min_rate_to_pass_dl; // after deadline
    uint256 public                          _commission_rate;
    uint256 public                          _tot_source_contribution;
    uint256 public                          _tot_target_contribution;
    uint256 public                          _tot_source_locked;
    uint256 public                          _tot_target_locked;
    string  public                          _project_meta;
    address[] public                        _holder_list;
    mapping (address => StakeHolder) public _stake_holders;

    uint256 public                          _num_proposals;
    mapping (uint => Proposal) public       _proposals;


    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }


    // core logics
    function initiate(address source_token,
                      address target_token,
                      uint256 price,
                      uint256 min_rate_to_pass_proposal,
                      uint256 min_rate_to_pass_request,
                      uint256 commission_rate,
                      string  calldata project_meta) external {
        require(_manager == address(0x0), "Project already initiated.");
        _manager                   = msg.sender;
        _source_token              = source_token;
        _target_token              = target_token;
        _price                     = price;
        _min_rate_to_pass_proposal = min_rate_to_pass_proposal;
        _min_rate_to_pass_request  = min_rate_to_pass_request;
        _commission_rate           = commission_rate;
        _project_meta              = project_meta;
        _tot_source_locked         = 0;
        _tot_target_locked         = 0;
        _min_rate_to_pass_dl       = 50;
        emit Init(source_token, target_token,
                  price, min_rate_to_pass_proposal,
                  min_rate_to_pass_request, commission_rate);
    }


    function deposit(address token,
                     uint256 amount) external {
        require(_holder_list.length <= 10); // FIXME we limit the size of investors for now, to avoid attack
        require(token == _source_token || token == _target_token, "token unrecognized");
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        StakeHolder storage stake_holder = _stake_holders[msg.sender];
        if(stake_holder._source_contribution == 0 && stake_holder._target_contribution==0) {
            _holder_list.push(msg.sender); // we allow the same holder to invest multiple times
        }
        if(token == _source_token) {
            stake_holder._source_contribution = stake_holder._source_contribution.add(amount); 
            _tot_source_contribution          = _tot_source_contribution.add(amount);
            
        } else {
            require(amount.mul(_price).add(_tot_target_contribution.mul(_price)) <= _tot_source_contribution,
                    "can not invest more than source token value");
            stake_holder._target_contribution = stake_holder._target_contribution.add(amount); 
            _tot_target_contribution          = _tot_target_contribution.add(amount);
        }
        emit Deposit(token, amount);
    }

    
    function withdraw(uint256 source_amount,
                      uint256 target_amount) external {
        uint256 tot_source_after_withdraw = _tot_source_contribution.sub(source_amount);
        uint256 tot_target_after_withdraw = _tot_target_contribution.sub(target_amount);
        require((source_amount < tot_source_after_withdraw && 
                target_amount < tot_target_after_withdraw),
                "Insufficient fund for withdraw");
        require(tot_source_after_withdraw.div(tot_target_after_withdraw) >= _price,
                "vote balance has been broken");
        StakeHolder storage stake_holder = _stake_holders[msg.sender];
        require(source_amount <= stake_holder._source_contribution && 
                target_amount <= stake_holder._target_contribution, 
                "You don't have enough fund to withdraw");
        // check pending proposal
        IBEP20(_source_token).transfer(msg.sender, source_amount);
        IBEP20(_target_token).transfer(msg.sender, target_amount);
        _tot_source_contribution = _tot_source_contribution.sub(source_amount);
        _tot_target_contribution = _tot_target_contribution.sub(target_amount);
        emit Withdraw(source_amount, target_amount);
    }


    function propose(string  calldata proposal_meta,
                     uint256 amount_target_token,
                     uint256 deadline) external {
        require(msg.sender == _manager, "only manager can propose"); // TODO anyone can propose
        require(amount_target_token <= _tot_target_contribution);
        Proposal storage proposal = _proposals[_num_proposals];
        proposal._proposal_meta   = proposal_meta;
        proposal._proposed_amount = amount_target_token;
        proposal._deadline        = deadline;
        _num_proposals = _num_proposals.add(1);
        emit Propose(_num_proposals, amount_target_token);
    }


    function is_proposal_approved(uint index) private view returns(bool) {
        // copmute total voting power
        Proposal storage proposal   = _proposals[index];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_approved_vote_power = proposal._tot_approved_vote_power;
        if(tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_proposal) {
            return true;
        } else if (proposal._deadline < getBlockNumber() && 
                  tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_dl) {
            return true;
        }
        return false;
    }


    function make_proposal_approved(uint index) private {
        Proposal storage proposal = _proposals[index];
        proposal._approved        = true;
        proposal._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price)); 
        _tot_target_locked = _tot_target_locked.add(proposal._proposed_amount);
        _tot_source_locked = _tot_source_locked.add(proposal._proposed_amount.mul(_price));
        emit ProposalApproved(index);
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
        emit ApproveProposal(index);
    }


    function is_proposal_rejected(uint index) private view returns(bool) {
        // copmute total voting power
        Proposal storage proposal   = _proposals[index];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_rejected_vote_power = proposal._tot_rejected_vote_power;
        if(tot_rejected_vote_power.mul(100).div(total_voting_power) > (100 - _min_rate_to_pass_proposal)) {
            return true;
        } else if(proposal._deadline < getBlockNumber() && 
                  tot_rejected_vote_power.mul(100).div(total_voting_power) > (100 - _min_rate_to_pass_dl)) {
            return true;
        }
        return false;
    }


    function make_proposal_rejected(uint index) private {
        Proposal storage proposal = _proposals[index];
        proposal._rejected        = true;
        proposal._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price)); 
        emit ProposalRejected(index);
    }


    function reject_proposal(uint            index,
                             string calldata reject_meta) external can_vote_proposal(index) {
        Proposal storage proposal = _proposals[index];
        proposal._proposal_rejections[msg.sender] = true;
        proposal._reject_meta[msg.sender]         = reject_meta;
        uint256 vote_power                        = get_vote_power(msg.sender);
        proposal._rejected_vote_power[msg.sender] = vote_power;
        proposal._tot_rejected_vote_power         = proposal._tot_rejected_vote_power.add(vote_power); 

        if(is_proposal_rejected(index) == true) {
            make_proposal_rejected(index);
        }
        emit RejectProposal(index);
    }


    function check_proposal(uint index) external returns (bool) {
        if(is_proposal_approved(index) == true) {
            make_proposal_approved(index);
            return true;
        } else if(is_proposal_rejected(index) == true) {
            make_proposal_rejected(index);
            return true;
        } 
        return false;
    }


    function is_request_approved(uint index, uint idx) private view returns(bool) {
        // copmute total voting power
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_approved_vote_power = request._tot_approved_vote_power;
        if(tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_request) {
            return true;
        } else if(request._deadline < getBlockNumber() &&
                  tot_approved_vote_power.mul(100).div(total_voting_power) >= _min_rate_to_pass_dl) {
            return true;
        }
        return false;
    }


    function is_request_rejected(uint index, uint idx) private view returns(bool) {
        // copmute total voting power
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        uint256 total_voting_power  = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        uint256 tot_rejected_vote_power = request._tot_rejected_vote_power;
        if(tot_rejected_vote_power.mul(100).div(total_voting_power) > (100 - _min_rate_to_pass_request)) {
            return true;
        } else if(request._deadline < getBlockNumber() && 
                  tot_rejected_vote_power.mul(100).div(total_voting_power) > (100 - _min_rate_to_pass_dl)) {
            return true;
        }
        return false;
    }


    function release_proposal(uint index, uint idx) private {
        Proposal storage proposal = _proposals[index];
        uint256 src_amnt = proposal._proposed_amount.mul(_price);
        uint256 tgt_amnt = proposal._proposed_amount;
        uint256 tgt_contributor = tgt_amnt.mul(100-_commission_rate).div(100);
        uint256 src_contributor = src_amnt.mul(_commission_rate).div(100); 
        PaymentRequest storage request = proposal._payment_requests[idx];         
        IBEP20(_source_token).transfer(request._contributor, src_contributor);
        IBEP20(_target_token).transfer(request._contributor, tgt_contributor);
        
        for(uint i=0; i<_holder_list.length; i++) {
            StakeHolder storage holder = _stake_holders[_holder_list[i]];
            uint256 src_ratio = holder._source_contribution.mul(100).div(_tot_source_contribution);
            uint256 tgt_ratio = holder._target_contribution.mul(100).div(_tot_target_contribution);
            // release to entrepreneur role 
            if (src_ratio != 0) {
                uint256 base = tgt_amnt.mul(_commission_rate);
                uint256 tgt_entrepreneur = base.mul(src_ratio).div(10000); 
                IBEP20(_target_token).transfer(_holder_list[i], tgt_entrepreneur);
                uint256 sub_src_amnt = src_amnt*src_ratio/100;
                holder._source_contribution = holder._source_contribution.sub(sub_src_amnt);
            }
            // release to investor role
            if (tgt_ratio != 0) {
                uint256 base = src_amnt.mul(100-_commission_rate);
                uint256 src_investor = base.mul(tgt_ratio).div(10000); 
                IBEP20(_source_token).transfer(_holder_list[i], src_investor);
                uint256 sub_tgt_amnt = tgt_amnt.mul(tgt_ratio).div(100);
                holder._target_contribution = holder._target_contribution.sub(sub_tgt_amnt);
            }
        }
        // update
        request._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price));
        _tot_source_contribution = _tot_source_contribution.sub(src_amnt); 
        _tot_target_contribution = _tot_target_contribution.sub(tgt_amnt); 
        proposal._released = true;
        emit PaymentReleased(index, idx);
    }


    function reject_request(uint index, uint idx) private {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        request._rejected        = true;
        request._tot_vote_power_at_termination = _tot_source_contribution.add(_tot_target_contribution.mul(_price)); 
        emit PaymentRejected(index, idx);
    }


    modifier can_request_payment(uint index) {
        require(index < _num_proposals);
        Proposal storage proposal = _proposals[index];
        require(proposal._approved == true && proposal._released == false);
        _;
    }


    function request_payment(uint            index,
                             uint            idx,
                             uint256         deadline,
                             string calldata payment_meta) external can_request_payment(index) {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        request._payment_request_meta = payment_meta;
        request._contributor = msg.sender;
        request._deadline = deadline;
        emit RequestPayment(index, idx);
    }


    modifier can_approve_request(uint index, uint idx) {
        require(index < _num_proposals);
        Proposal storage proposal = _proposals[index];
        require(proposal._approved == true && proposal._released == false);
        PaymentRequest storage request = proposal._payment_requests[idx];         
        require(request._request_approvals[msg.sender] == false);
        require(request._request_rejections[msg.sender] == false);
        _;
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
            release_proposal(index, idx);
        }
        emit ApprovePayment(index, idx);
    }


    function reject_payment(uint            index,
                            uint            idx,
                            string calldata reject_meta) external {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx];
        request._request_rejections[msg.sender]  = true;
        request._reject_meta[msg.sender]         = reject_meta;
        uint256 vote_power                       = get_vote_power(msg.sender);
        request._rejected_vote_power[msg.sender] = vote_power;
        request._tot_rejected_vote_power         = request._tot_rejected_vote_power.add(vote_power); 

        if(is_request_rejected(index, idx) == true) {
            reject_request(index, idx);
        }
        emit RejectPayment(index, idx);
    } 


    function check_payment(uint index,
                           uint idx) external returns(bool) {
        if(is_request_approved(index, idx)) {
            release_proposal(index, idx);
            return true;
        } else if(is_request_rejected(index, idx)) {
            reject_request(index, idx);
            return true;
        }
        return false;
    }


    function get_proposal_voter_info(uint index,
                               address voter) external view
                            returns (bool, bool, uint256, uint256, string memory, string memory) {
        Proposal storage proposal = _proposals[index]; 
        return (proposal._proposal_approvals[voter], proposal._proposal_rejections[voter],
                proposal._approved_vote_power[voter], proposal._rejected_vote_power[voter],
                proposal._approval_meta[voter], proposal._reject_meta[voter]);
    }


    function get_request_voter_info(uint index,
                                    uint idx,
                                    address voter) external view
                            returns (bool, bool, uint256, uint256, string memory, string memory) {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx]; 
        return (request._request_approvals[voter], request._request_rejections[voter],
                request._approved_vote_power[voter], request._rejected_vote_power[voter],
                request._approval_meta[voter], request._reject_meta[voter]);
    }


    function get_request_info(uint index,
                              uint idx) external view
                            returns (address, string memory, bool, bool, uint256, uint256, uint256) {
        PaymentRequest storage request = _proposals[index]._payment_requests[idx]; 
        return (request._contributor, request._payment_request_meta, request._approved,
                request._rejected, request._tot_approved_vote_power, request._tot_rejected_vote_power,
                request._tot_vote_power_at_termination);
    }
}
