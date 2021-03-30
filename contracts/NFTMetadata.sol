// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./NFT.sol";
import "./interfaces/IERC721Metadata.sol";

contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  string internal nftName;
  string internal nftSymbol;
  mapping (uint256 => string) internal idToUri;


  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }


  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }


  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }


  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }


  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }


  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}

