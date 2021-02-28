// test/Box.test.js
// Load dependencies
const { expect, assert } = require('chai');
const bigNumberify = ethers.BigNumber.from;

// Start test block
describe('Project', function () {
  before(async function () {
    this.Project = await ethers.getContractFactory("Project");
    this.Token0 = await ethers.getContractFactory("BEP20Token");
    this.Token1 = await ethers.getContractFactory("BEP20Token");
  });

  beforeEach(async function () {
    this.project = await this.Project.deploy();
    await this.project.deployed();
    this.token0 = await this.Token0.deploy();
    await this.token0.deployed();
    this.token1 = await this.Token1.deploy();
    await this.token1.deployed();
  });

  // Test case
  it('project can only initiate once', async function () {
    const [owner, other] = await ethers.getSigners();
    
    await this.project.connect(owner).initiate(this.token0.address,
                                this.token1.address,
                                10,
                                90,
                                90,
                                10,
                                "first project");

    expect (await this.project._manager()).to.equal(owner.address);
    expect (await this.project._source_token()).to.equal(this.token0.address);
    expect (await this.project._target_token()).to.equal(this.token1.address);
    assert.deepEqual(await this.project._price(), bigNumberify('10'));
    assert.deepEqual(await this.project._min_rate_to_pass_proposal(), bigNumberify('90'));
    assert.deepEqual(await this.project._min_rate_to_withdraw(), bigNumberify('90'));
    assert.deepEqual(await this.project._commission_rate(), bigNumberify('10'));
    expect (await this.project._project_meta()).to.equal("first project");

    let throwed = false;
    try {
        await this.project.connect(other).initiate(this.token0.address,
                                this.token1.address,
                                10,
                                90,
                                90,
                                10,
                                "first project");
    } catch (err) {
        throwed = true;
    }
    expect (throwed).to.equal(true);

  });
});