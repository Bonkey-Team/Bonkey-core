// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC721Tokenized
{

    function initialize(string calldata metadata,
                        address t_token,
                        uint256 u_size,
                        uint256 max_n_units) external; 

    function meta()
        external
        view
        returns (string memory _meta);

    function tgt_token_addr() external view returns(address);

    function unit_size()
        external
        view
        returns (uint256 _uint_size);

    function max_num_units()
        external
        view
        returns (uint256 _max_num_units);

    function tokenPrice(uint256 _tokenId)
        external
        view
        returns (uint256);

    function set_manager(address manager) external;

    function add_product(uint256 product_id,
                         uint256 price) external;

    function redeem_product(uint256 product_id) external;

    function disable_product_sell(uint256 product_id) external;
}
