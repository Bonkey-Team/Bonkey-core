// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './interfaces/IBonkeyFactory.sol';
import './interfaces/IBonkeyRouter.sol';
import './interfaces/IProject.sol';

// import './interfaces/IBEP20.sol';
// TODO do not support ETH at the moment

contract BonkeyRouter is IBonkeyRouter {

    function createProject(address source_token,
                           address target_token,
                           uint256 price,
                           uint256 min_rate_to_pass_proposal,
                           uint256 min_rate_to_withdraw,
                           uint256 commission_rate,
                           string  calldata project_meta) external override returns (address project) {
    }


    function deposite(address source_token,
                      address target_token,
                      address token,
                      uint256 amount) external override {
    }


    function propose(address source_token,
                     address target_token,
                     string  calldata proposal_meta,
                     uint256 amount_target_token) external override {
    }


    function approve_proposal(address          source_token,
                              address          target_token,
                              uint256          index,
                              string  calldata approve_meta) external override {
    }


    function reject_proposal(address         source_token,
                             address         target_token,
                             uint            index,
                             string calldata reject_meta) external override {
    }


    function request_payment(address         source_token,
                             address         target_token,
                             uint            index,
                             uint            idx,
                             string calldata payment_meta) external override {
    }


    function approve_payment(address         source_token,
                             address         target_token,
                             uint            index,
                             uint            idx,
                             string calldata approve_meta) external override {
    }


    function reject_payment(address         source_token,
                            address         target_token,
                            uint            index,
                            uint            idx,
                            string calldata reject_meta) external override {
    }


    function get_proposal_voter_info(address source_token,
                                     address target_token,
                                     uint    index,
                                     address voter) external override view
                            returns (bool, bool, uint256, uint256, string memory, string memory) {
    }


    function get_request_voter_info(address source_token,
                                    address target_token,
                                    uint    index,
                                    uint    idx,
                                    address voter) external override view
                            returns (bool, bool, uint256, uint256, string memory, string memory) {
    }


    function get_request_info(address source_token,
                              address target_token,
                              uint index,
                              uint idx) external override view
                            returns (address, string memory, bool, bool, uint256, uint256, uint256) {
    }
}
