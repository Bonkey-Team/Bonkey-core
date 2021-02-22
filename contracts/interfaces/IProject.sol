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
    function approve_proposal(uint256 index,
                              string  calldata approve_meta) external;
    //function reject_proposal(uint index,
    //                         string reject_meta) external;
    //function withdraw(uint index,
    //                  string withdraw_meta) external;
    //function approve_withdraw(uint index,
    //                          string approve_meta) external;
    //function reject_withdraw(uint index,
    //                         string reject_meta) external;
    //// read / list logics
    //function get_project_info() external view returns (uint, uint, uint, string);
    //function get_stake_holders() external view returns (address[]);
    //function get_stake_holder_info(address) external view returns (uint, uint);
    //function get_num_proposals() external view returns (uint);
    //function get_proposal_info(uint index) external view returns (string, string[], string[]);
    //function get_num_withdraws() external view returns (uint);
    //function get_withdraw_info(uint index, uint index) external view returns (string, string[], string[]);
}
