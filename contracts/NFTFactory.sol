// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './interfaces/INFTFactory.sol';
import './NFTMetadata.sol';

contract NFTFactory is INFTFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(NFTokenMetadata).creationCode));

    mapping(string => mapping(uint => address)) public getNFT; // we allow same pair to exist multiple times
    mapping(string => uint) public nftNumber;
    address[] public allNFTs;


    function allNFTsLength() external view returns (uint) {
        return allNFTs.length;
    }


    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    function createNFT(string calldata nftName,
                       string calldata nftSymbol) external override returns (address nft)
    {
        bytes memory bytecode = type(NFTokenMetadata).creationCode;
        bytes32 salt0 = keccak256(abi.encodePacked(nftName, nftSymbol));
        string memory converted = bytes32ToStr(salt0);
        uint count = nftNumber[converted];
        bytes32 salt1 = keccak256(abi.encodePacked(nftName, nftSymbol, count));
        assembly {
            nft := create2(0, add(bytecode, 32), mload(bytecode), salt1)
        }
        ERC721Metadata(nft).set_manager(msg.sender);
        getNFT[converted][count] = nft;
        allNFTs.push(nft);
        nftNumber[converted] = nftNumber[converted] + 1;
        emit NFTCreated(nft);
    }
}
