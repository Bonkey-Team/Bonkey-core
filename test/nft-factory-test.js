// test/nft-factory-test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;
var project_json = require('../artifacts/contracts/NFTFactory.sol/NFTFactory.json');
var project_abi = project_json['abi']

// Start test block
describe('NFTFactory', function () {
    before(async function () {
        this.NFTFactory = await ethers.getContractFactory("NFTFactory");
    });

    beforeEach(async function () {
        const [owner, other] = await ethers.getSigners();
        this.factory = await this.NFTFactory.deploy();
        await this.factory.deployed();
    });

    it('can use factory to deploy NFT', async function () {
        const [owner, other] = await ethers.getSigners();
        await this.factory.connect(owner).createNFT('Test NFT', 'TEST');

        let nft_address = await this.factory.connect(owner).allNFTs(0);
        expect (nft_address).to.not.eq(0);
    });

});
