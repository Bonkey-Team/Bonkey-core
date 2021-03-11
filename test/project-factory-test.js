// test/Box.test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;
var project_json = require('../artifacts/contracts/Project.sol/Project.json');
var project_abi = project_json['abi']

// Start test block
describe('ProjectFactory', function () {
    before(async function () {
        this.BonkeyFactory = await ethers.getContractFactory("BonkeyFactory");
        this.Token0 = await ethers.getContractFactory("BEP20Token");
        this.Token1 = await ethers.getContractFactory("BEP20Token");
    });

    beforeEach(async function () {
        const [owner, other] = await ethers.getSigners();
        this.factory = await this.BonkeyFactory.deploy();
        await this.factory.deployed();
        this.token0 = await this.Token0.deploy();
        await this.token0.deployed();
        this.token1 = await this.Token1.deploy();
        await this.token1.deployed();
    });

    it('can use factory to deploy project', async function () {
        const [owner, other] = await ethers.getSigners();
        await this.factory.connect(owner).createProject(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");

        let project_address = await this.factory.connect(owner).allPairs(0);
        expect (project_address).to.not.eq(0);
    });

});
