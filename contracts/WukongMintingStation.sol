// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './ERC721.sol';
import './abstracts/AccessControl.sol';
import './BonkeyWukongs.sol';

contract WukongMintingStation is AccessControl {
    BonkeyWukongs public bonkeyWukongs;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Not a minting role");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an admin role");
        _;
    }


    function initialize (
    ) public initializer {
        bonkeyWukongs = BonkeyWukongs(0x2e556e732c9762bcefF399AdF57018fb93998974);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    function mintCollectible(
        address _tokenReceiver,
        string calldata _tokenURI,
        uint8 _wukongId
    ) external onlyMinter returns (uint256) {
        uint256 tokenId =
            bonkeyWukongs.mint(_tokenReceiver, _tokenURI, _wukongId);
        return tokenId;
    }

    function setWukongName(uint8 _wukongId, string calldata _wukongName)
        external
        onlyOwner
    {
        bonkeyWukongs.setWukongName(_wukongId, _wukongName);
    }

    function changeOwnershipNFTContract(address _newOwner) external onlyOwner {
        bonkeyWukongs.transferOwnership(_newOwner);
    }
}
