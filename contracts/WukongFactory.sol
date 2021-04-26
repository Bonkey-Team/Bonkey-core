// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './abstracts/Ownable.sol';
import './libraries/SafeBEP20.sol';
import './WukongMintingStation.sol';

contract WukongFactory is Ownable {
    using SafeBEP20 for IBEP20;

    WukongMintingStation public wukongMintingStation;

    IBEP20 public bnkyToken;

    uint256 public startBlockNumber;
    uint256 public tokenPrice;
    mapping(address => bool) public hasClaimed;
    string private ipfsHash;
    uint8 private constant numberWukongIds = 10;
    uint8 private constant previousNumberWukongIds = 5;
    mapping(uint8 => string) private wukongIdURIs;
    event WukongMint(
        address indexed to,
        uint256 indexed tokenId,
        uint8 indexed wukongId
    );

    function initialize (
    ) public initializer {
        wukongMintingStation = WukongMintingStation(0x300440ED8B143cA4d6730b2aD3f60c2EC0D104E3);
        bnkyToken = IBEP20(0xAdc8e9B18b671DF686acCe0543F086293f2ef886);
        tokenPrice = 200000000000000000000;
        ipfsHash = 'wukong';
        startBlockNumber = 6489991;
        __Ownable_init();
    }

    
    function mintNFT(uint8 _wukongId) external {
        address senderAddress = _msgSender();

        require(!hasClaimed[senderAddress], "Has claimed");
        require(block.number > startBlockNumber, "too early");
        require(_wukongId >= previousNumberWukongIds, "wukongId too low");
        require(_wukongId < numberWukongIds, "wukongId too high");

        hasClaimed[senderAddress] = true;

        bnkyToken.safeTransferFrom(senderAddress, address(this), tokenPrice);

        string memory tokenURI = wukongIdURIs[_wukongId];

        uint256 tokenId =
            wukongMintingStation.mintCollectible(
                senderAddress,
                tokenURI,
                _wukongId
            );

        emit WukongMint(senderAddress, tokenId, _wukongId);
    }

    function claimFee(uint256 _amount) external onlyOwner {
        bnkyToken.safeTransfer(_msgSender(), _amount);
    }

    function setWukongJson(
        string calldata _wukongId5Json,
        string calldata _wukongId6Json,
        string calldata _wukongId7Json,
        string calldata _wukongId8Json,
        string calldata _wukongId9Json
    ) external onlyOwner {
        wukongIdURIs[5] = string(abi.encodePacked(ipfsHash, _wukongId5Json));
        wukongIdURIs[6] = string(abi.encodePacked(ipfsHash, _wukongId6Json));
        wukongIdURIs[7] = string(abi.encodePacked(ipfsHash, _wukongId7Json));
        wukongIdURIs[8] = string(abi.encodePacked(ipfsHash, _wukongId8Json));
        wukongIdURIs[9] = string(abi.encodePacked(ipfsHash, _wukongId9Json));
    }

    function setStartBlockNumber(uint256 _newStartBlockNumber)
        external
        onlyOwner
    {
        require(_newStartBlockNumber > block.number, "too short");
        startBlockNumber = _newStartBlockNumber;
    }

    function updateTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    function canMint(address userAddress) external view returns (bool) {
        if (
            (hasClaimed[userAddress])
        ) {
            return false;
        } else {
            return true;
        }
    }
}
