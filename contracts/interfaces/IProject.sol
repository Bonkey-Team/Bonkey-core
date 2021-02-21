pragma solidity >=0.5.0;

interface IProject {
    // core logics
    function initiate(address source_token,
                      address target_token,
                      uint price,
                      uint min_rate_to_withdraw,
                      uint commission_rate,
                      string project_meta) external pure;
    function deposit(address token,
                     uint amount) external pure;
    function propose(string propose_meta,
                     uint amount_target_token) external pure;
    function approve_proposal(uint index,
                              string approve_meta) external pure;
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
