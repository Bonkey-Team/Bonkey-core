// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ERC721Metadata
{
    function name()
        external
        view
        returns (string memory _name);

    function symbol()
        external
        view
        returns (string memory _symbol);

    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);

    function set_manager(address manager) external;

    function add_product(uint256 product_id,
                         string  calldata product_uri) external;

    function redeem_product(uint256 product_id) external;
}
