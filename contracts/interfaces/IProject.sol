pragma solidity >=0.5.0;

interface IProject {
    // core logics
    event Init(address source_token,
               address target_token,
               uint256 price,
               uint256 min_rate_to_pass_proposal,
               uint256 min_rate_to_withdraw,
               uint256 commission_rate);
    function initiate(address source_token,
                      address target_token,
                      uint256 price,
                      uint256 min_rate_to_pass_proposal,
                      uint256 min_rate_to_withdraw,
                      uint256 commission_rate,
                      string  calldata project_meta) external returns (bool); 

    event Deposit(address token,
                  uint256 amount);
    function deposit(address token,
                     uint256 amount) external returns (bool); 

    event Withdraw(uint256 source_amount,
                   uint256 target_amount);
    function withdraw(uint256 source_amount,
                      uint256 target_amount) external returns (bool); 

    event Propose(uint    idx,
                  uint256 amount_target_token);
    function propose(string  calldata proposal_meta,
                     uint256 amount_target_token,
                     uint256 deadline) external returns (bool); 

    event ApproveProposal(uint256 index);
    event ProposalApproved(uint256 index);
    function approve_proposal(uint256          index,
                              string  calldata approve_meta) external returns(bool);

    event RejectProposal(uint index);
    event ProposalRejected(uint index);
    function reject_proposal(uint            index,
                             string calldata reject_meta) external returns(bool);

    event RequestPayment(uint index,
                         uint idx);
    function request_payment(uint            index,
                             uint            idx,
                             uint256         deadline,
                             string calldata payment_meta) external returns(bool);

    event ApprovePayment(uint index,
                         uint idx);
    event PaymentReleased(uint index,
                          uint idx);
    function approve_payment(uint            index,
                             uint            idx,
                             string calldata approve_meta) external returns(bool);

    event RejectPayment(uint index,
                        uint idx);
    event PaymentRejected(uint index,
                          uint idx);
    function reject_payment(uint            index,
                            uint            idx,
                            string calldata reject_meta) external returns(bool);

    function get_proposal_voter_info(uint index,
                               address voter) external view
                            returns (bool, bool, uint256, uint256, string memory, string memory);
    function get_request_voter_info(uint index,
                                    uint idx,
                                    address voter) external view
                            returns (bool, bool, uint256, uint256, string memory, string memory);
    function get_request_info(uint index,
                              uint idx) external view
                            returns (address, string memory, bool, bool, uint256, uint256, uint256);
}
