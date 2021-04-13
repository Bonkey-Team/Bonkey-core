// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWeiBuy {

    function set_manager(
        address manager
    ) external;

    function set_nft_fatory(
        address factory_addr
    ) external;

    function create_token_NFT(
            address src_token,
            address tgt_token,
            string calldata meta,
            uint256 price,
            uint256 unit_size,
            uint256 num_units
    ) external;

    function buy_token_NFT(
            uint nft_id,
            uint token_id 
    ) external;

    function sell_token_NFT(
            uint nft_id,
            uint token_id, 
            uint256 price
    ) external;

    function redeem_token_NFT(
            uint nft_id,
            uint token_id
    ) external;
}
