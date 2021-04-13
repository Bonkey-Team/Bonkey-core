// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./NFT.sol";
import "./interfaces/IERC721Tokenized.sol";

contract NFTokenTokenized is
NFToken,
    IERC721Tokenized 
{

    address public                        _manager;
    string public                         _meta;
    address public                        _tgt_token_addr;
    uint256 public                        _num_units;
    uint256 public                        _max_num_units;
    uint256 public                        _unit_size;
    mapping (uint256 => uint256) internal idToPrice;
    mapping (uint256 => bool) internal saleDisabled;


    constructor()
    {
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    }

    function unit_size()
        external
        view
        override
        returns (uint256 _uint_size) {
            return _unit_size;
        }

    function max_num_units()
        external
        view
        override
        returns (uint256 _uint_size) {
            return _max_num_units;
        }



    function tgt_token_addr() external view override returns(address) {
        return _tgt_token_addr;
    }


    function set_manager(address manager) external override
    {
        require(_manager == address(0x0) || _manager == msg.sender, 
                'you are not allowed to perform this operation');
        _manager = manager; 
    }

    function initialize(string calldata metadata,
            address tgt_token,
            uint256 u_size, 
            uint256 max_n_units) external override
    {
        require(msg.sender == _manager || _manager == address(0x0), 
                'you are not allowed to perform this operation.');
        _meta = metadata; 
        _tgt_token_addr = tgt_token;
        _unit_size = u_size;
        _max_num_units = max_n_units;
    }

    function add_product(uint256 product_id,
            uint256 price) external override
    {
        require(msg.sender == _manager, 'only manager can create product');
        _mint(msg.sender, product_id);
        _setTokenPrice(product_id, price);
    }


    function redeem_product(uint256 product_id) external override {
        //require(msg.sender == _manager, 'only manager can create product');
        _burn(product_id);
    }


    function disable_product_sell(uint256 product_id) external override {
        
    }

    function meta()
        external
        override
        view
        returns (string memory )
        {
            return _meta;
        }


    function tokenPrice(
            uint256 _tokenId
            )
        external
        override
        view
        validNFToken(_tokenId)
        returns (uint256)
        {
            return idToPrice[_tokenId];
        }


    function _burn(
            uint256 _tokenId
            )
        internal
        override
        virtual
        {
            super._burn(_tokenId);

            if (idToPrice[_tokenId] != 0)
            {
                delete idToPrice[_tokenId];
            }
        }


    function _setTokenPrice(
            uint256 _tokenId,
            uint256 _price
            )
        internal
        validNFToken(_tokenId)
        {
            idToPrice[_tokenId] = _price;
        }

}

