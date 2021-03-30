// test/nft.test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;
var nft_meta_json = require('../artifacts/contracts/NFTMetadata.sol/NFTokenMetadata.json');
var nft_meta_abi = nft_meta_json['abi']

// Start test block
describe('NFTMetadata', function () {
    before(async function () {
        this.NFTMetadata = await ethers.getContractFactory("NFTokenMetadata");
    });

    beforeEach(async function () {
        const [owner, other] = await ethers.getSigners();
        this.nft_meta = await this.NFTMetadata.deploy();
        await this.nft_meta.deployed();
    });

    it('can add product', async function () {
        const [owner, other] = await ethers.getSigners();
        await this.nft_meta.connect(owner).set_manager(owner.address)
        await this.nft_meta.connect(owner).add_product(1, 'nft meta')
        let owner_addr = await this.nft_meta.ownerOf(1)
        let uri = await this.nft_meta.tokenURI(1) 
        expect(owner_addr).to.equal(owner.address);
        expect(uri).to.equal('nft meta');
    });

});
