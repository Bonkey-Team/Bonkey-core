// test/nft-factory-test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;
var project_json = require('../artifacts/contracts/NFTFactory.sol/NFTFactory.json');
var project_abi = project_json['abi']
const IPFS = require('ipfs-core')

// Start test block
describe('NFTFactory', function () {
    before(async function () {
        this.NFTFactory = await ethers.getContractFactory("NFTFactory");
        this.ipfs = await IPFS.create()
        this.Token0 = await ethers.getContractFactory("BEP20Token");
    });

    beforeEach(async function () {
        const [owner, other] = await ethers.getSigners();
        this.factory = await this.NFTFactory.deploy();
        await this.factory.deployed();
        this.token0 = await this.Token0.deploy();
        await this.token0.deployed();
    });

    it('can use factory to deploy NFT', async function () {
        const [owner, other] = await ethers.getSigners();
        const { cid } = await this.ipfs.add('Test NFT, TEST')
        console.log(cid)
        await this.factory.connect(owner).createNFT(cid, this.token0.address, 1, 1);

        let nft_address = await this.factory.connect(owner).allNFTs(0);
        expect (nft_address).to.not.eq(0);
    });

});
