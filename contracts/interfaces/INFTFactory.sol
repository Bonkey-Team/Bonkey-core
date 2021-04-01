// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface INFTFactory {
    event NFTCreated(address indexed nftAddr);

    function createNFT(string calldata nftName,
                       string calldata nftSymbol) external returns (address nftAddr);

}
