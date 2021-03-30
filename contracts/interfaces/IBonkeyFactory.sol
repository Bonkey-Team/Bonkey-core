// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBonkeyFactory {
    event ProjectCreated(address indexed token0, address indexed token1, address project, uint);

    function createProject(address source_token,
                           address target_token,
                           uint256 price,
                           uint256 min_rate_to_pass_proposal,
                           uint256 min_rate_to_withdraw,
                           uint256 commission_rate,
                           string  calldata project_meta) external returns (address project);

    // for possible future usage
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
