// test/personal-info-test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;
var personal_info_json = require('../artifacts/contracts/PersonalInfo.sol/PersonalInfo.json');
var personal_info_abi = personal_info_json['abi']

// Start test block
describe('PersonalInfo', function () {
    before(async function () {
        this.PersonalInfo = await ethers.getContractFactory("PersonalInfo");
    });

    beforeEach(async function () {
        const [owner, other] = await ethers.getSigners();
        this.info = await this.PersonalInfo.deploy();
        await this.info.deployed();
    });

    it('can create personal info', async function () {
        const [owner, other, third] = await ethers.getSigners();
        await this.info.connect(owner).create_personal_info(owner.address, 'owner meta');

        await this.info.connect(owner).allow_access(other.address, 100000, 'allowed');

        let throwed = false;
        try {
            await this.info.connect(other).create_personal_info(owner.address, 'owner meta');
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);

        throwed = false;
        try {
            await this.info.connect(other).allow_access(other.address, 10000, 'allowed');
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);

        let info = await this.info.connect(owner).get_personal_info()
        expect (info).to.equal("owner meta");

        info = await this.info.connect(other).get_personal_info()
        expect (info).to.equal("owner meta");

        throwed = false;
        try {
            info = await this.info.connect(third).get_personal_info()
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);
    });
});
