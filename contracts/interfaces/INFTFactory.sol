// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface INFTFactory {
    event NFTCreated(address indexed nftAddr);

    function createNFT(string calldata meta, 
                       address tgt_token,
                       uint256 unit_size,
                       uint256 max_n_units) external returns (address nftAddr);

    function get_NFT(uint256 index) external view returns (address);
}
