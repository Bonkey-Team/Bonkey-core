pragma solidity >=0.5.0;

interface IProject {
    // core logics
    function initiate(address source_token,
                      address target_token,
                      uint256 price,
                      uint256 min_rate_to_pass_proposal,
                      uint256 min_rate_to_withdraw,
                      uint256 commission_rate,
                      string  calldata project_meta) external; 
    function deposit(address token,
                     uint256 amount) external; 
    function propose(string  calldata proposal_meta,
                     uint256 amount_target_token) external; 
    function approve_proposal(uint256          index,
                              string  calldata approve_meta) external;
    function reject_proposal(uint            index,
                             string calldata reject_meta) external;
    function request_payment(uint            index,
                             uint            idx,
                             string calldata payment_meta) external;
    function approve_payment(uint            index,
                             uint            idx,
                             string calldata approve_meta) external;
    function reject_payment(uint            index,
                            uint            idx,
                            string calldata reject_meta) external;
}
