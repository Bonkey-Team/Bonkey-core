// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './interfaces/IWeiBuy.sol';
import './interfaces/IBEP20.sol';
import './interfaces/INFTFactory.sol';
import './interfaces/IERC721Tokenized.sol';
import './interfaces/IERC721.sol';
import './libraries/SafeMath.sol';

contract WeiBuy is IWeiBuy {

    using SafeMath for uint256; 

    address public _manager;
    address public _nft_factory;


    function set_manager (
        address manager
    ) external override {
        require(_manager == address(0x0) || _manager == msg.sender,
               'action not allowed');
        _manager = manager;
    }


    function set_nft_fatory (
        address factory_addr
    ) external override {
        require(msg.sender == _manager, 'you are not allowed to reset factory address');
        _nft_factory = factory_addr;
    }


    function create_token_NFT (
            address src_token,
            address tgt_token,
            string calldata meta,
            uint256 price,
            uint256 unit_size,
            uint256 num_units
    ) external override {
        uint256 tot_amount = unit_size.mul_ratio(price); 
        uint256 balance = IBEP20(src_token).balanceOf(msg.sender);
        uint256 allowance = IBEP20(src_token).allowance(msg.sender, address(this));
        require(tot_amount <= balance && tot_amount <= allowance, 
                'balance not enough, can not create!');
        address nft_addr = INFTFactory(_nft_factory).createNFT(meta, tgt_token, unit_size, num_units);
        IBEP20(src_token).transferFrom(msg.sender, address(this), tot_amount);
        for (uint i=0; i<num_units; i++) {
            IERC721Tokenized(nft_addr).add_product(i+1, price);
        }
    }


    function buy_token_NFT (
            uint nft_id,
            uint token_id 
    ) external override {
        address nft_addr = INFTFactory(_nft_factory).get_NFT(nft_id);   
        uint256 u_size = IERC721Tokenized(nft_addr).unit_size();
        uint256 price = IERC721Tokenized(nft_addr).tokenPrice(token_id);
        uint256 tot_tgt_pay_amount = u_size.mul_ratio(price);
        address old_owner_addr = ERC721(nft_addr).ownerOf(token_id); 
        address tgt_token = IERC721Tokenized(nft_addr).tgt_token_addr(); 
        IBEP20(tgt_token).transferFrom(msg.sender, old_owner_addr, tot_tgt_pay_amount);
        ERC721(nft_addr).transferFrom(old_owner_addr, msg.sender, token_id);
    }


    function sell_token_NFT (
            uint nft_id,
            uint token_id, 
            uint256 price
    ) external override {
    }


    function redeem_token_NFT (
            uint nft_id,
            uint token_id
    ) external override {
    }
}
