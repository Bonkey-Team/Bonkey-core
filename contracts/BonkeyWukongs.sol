// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './ERC721.sol';
import './abstracts/Ownable.sol';
import './libraries/Counters.sol';

contract BonkeyWukongs is ERC721, Ownable {
    using Counters for Counters.Counter;

    mapping(uint8 => uint256) public wukongCount;
    mapping(uint8 => uint256) public wukongBurnCount;
    Counters.Counter private _tokenIds;
    mapping(uint256 => uint8) private wukongIds;

    mapping(uint8 => string) private wukongNames;


    function initialize (
    ) public initializer {
        __ERC721_init("Bonkey Wukongs", "BW");
        _setBaseURI("wukong");
        __Ownable_init();
    }


    function getWukongId(uint256 _tokenId) external view returns (uint8) {
        return wukongIds[_tokenId];
    }

    function getWukongName(uint8 _wukongId)
        external
        view
        returns (string memory)
    {
        return wukongNames[_wukongId];
    }

    function getWukongNameOfTokenId(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        uint8 wukongId = wukongIds[_tokenId];
        return wukongNames[wukongId];
    }

    function mint(
        address _to,
        string calldata _tokenURI,
        uint8 _wukongId
    ) external onlyOwner returns (uint256) {
        uint256 newId = _tokenIds.current();
        _tokenIds.increment();
        wukongIds[newId] = _wukongId;
        wukongCount[_wukongId] = wukongCount[_wukongId]  + 1;
        _mint(_to, newId);
        _setTokenURI(newId, _tokenURI);
        return newId;
    }

    function setWukongName(uint8 _wukongId, string calldata _name)
        external
        onlyOwner
    {
        wukongNames[_wukongId] = _name;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        uint8 wukongIdBurnt = wukongIds[_tokenId];
        wukongCount[wukongIdBurnt] = wukongCount[wukongIdBurnt] - 1;
        wukongBurnCount[wukongIdBurnt] = wukongBurnCount[wukongIdBurnt] + 1;
        _burn(_tokenId);
    }
}
