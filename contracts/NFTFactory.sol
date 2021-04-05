// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './interfaces/INFTFactory.sol';
import './NFTTokenized.sol';

contract NFTFactory is INFTFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(NFTokenTokenized).creationCode));

    mapping(string => mapping(uint => address)) public getNFT; // we allow same pair to exist multiple times
    mapping(string => uint) public nftNumber;
    address[] public allNFTs;


    function allNFTsLength() external view returns (uint) {
        return allNFTs.length;
    }

    function get_NFT(uint256 index) external view override returns (address) {
        return allNFTs[index];
    }


    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    function createNFT(string calldata meta,
                       address tgt_token,
                       uint256 unit_size,
                       uint256 max_n_units) external override returns (address nft)
    {
        bytes memory bytecode = type(NFTokenTokenized).creationCode;
        bytes32 salt0 = keccak256(abi.encodePacked(meta));
        string memory converted = bytes32ToStr(salt0);
        uint count = nftNumber[converted];
        bytes32 salt1 = keccak256(abi.encodePacked(meta, count));
        assembly {
            nft := create2(0, add(bytecode, 32), mload(bytecode), salt1)
        }
        NFTokenTokenized(nft).initialize(meta, tgt_token, unit_size, max_n_units);
        NFTokenTokenized(nft).set_manager(msg.sender);
        getNFT[converted][count] = nft;
        allNFTs.push(nft);
        nftNumber[converted] = nftNumber[converted] + 1;
        emit NFTCreated(nft);
    }
}
