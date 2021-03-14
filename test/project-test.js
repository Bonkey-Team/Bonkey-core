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


    it('project can only initiate once', async function () {
        const [owner, other] = await ethers.getSigners();
        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");

        expect (await this.project._manager()).to.equal(owner.address);
        expect (await this.project._source_token()).to.equal(this.token0.address);
        expect (await this.project._target_token()).to.equal(this.token1.address);
        assert.deepEqual(await this.project._price(), bigNumberify('10'));
        assert.deepEqual(await this.project._min_rate_to_pass_proposal(), bigNumberify('90'));
        assert.deepEqual(await this.project._min_rate_to_pass_request(), bigNumberify('90'));
        assert.deepEqual(await this.project._commission_rate(), bigNumberify('10'));
        expect (await this.project._project_meta()).to.equal("first project");

        let throwed = false;
        try {
            await this.project.connect(other).initiate(this.token0.address,
                this.token1.address, 10, 90, 90, 10, "first project");
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);

    });


    it('can deposit', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        let own = await this.project._stake_holders(owner.address);
        assert.deepEqual (own[0], bigNumberify(wei_of_10_ether));

        let inv = await this.project._stake_holders(investor.address);
        assert.deepEqual (inv[1], bigNumberify(wei_of_1_ether));
    });


    it('can propose', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        await this.project.propose("first proposal", wei_of_05_ether,
            100);

        assert.deepEqual(await this.project._num_proposals(), bigNumberify('1'));

        let prop = await this.project._proposals(0);
        expect(prop[0]).to.equal('first proposal')
        assert.deepEqual(prop[1], bigNumberify(wei_of_05_ether));
    });


    it('can approve proposal', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")
        let wei_of_20_ether = ethers.utils.parseEther("20")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        await this.project.propose("first proposal", wei_of_05_ether, 100000000000);
        await this.project.approve_proposal(0, "owner's approval");

        let prop = await this.project._proposals(0);
        assert.deepEqual(prop[5], bigNumberify(wei_of_10_ether)); // vote power
        expect(prop[2]).to.equal(false)
        expect(prop[3]).to.equal(false)
        expect(prop[4]).to.equal(false)

        await this.project.connect(investor).approve_proposal(0, "investor 's approval");

        prop = await this.project._proposals(0);
        assert.deepEqual(prop[5], bigNumberify(wei_of_20_ether));
        expect(prop[2]).to.equal(true);
        expect(prop[3]).to.equal(false);
        expect(prop[4]).to.equal(false);
    });


    it('can reject proposal', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")
        let wei_of_20_ether = ethers.utils.parseEther("20")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        await this.project.propose("first proposal", wei_of_05_ether, 1000);
        await this.project.approve_proposal(0, "owner's approval");

        let prop = await this.project._proposals(0);
        assert.deepEqual(prop[5], bigNumberify(wei_of_10_ether)); // vote power
        expect(prop[2]).to.equal(false);
        expect(prop[3]).to.equal(false);
        expect(prop[4]).to.equal(false);

        await this.project.connect(investor).reject_proposal(0, "investor 's rejection");

        prop = await this.project._proposals(0);
        assert.deepEqual(prop[5], bigNumberify(wei_of_10_ether));
        expect(prop[2]).to.equal(false);
        expect(prop[3]).to.equal(true);
        expect(prop[4]).to.equal(false);
    });


    it('can approve payment request', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")
        let wei_of_045_ether = ethers.utils.parseEther("0.45")
        let wei_of_4_5_ether = ethers.utils.parseEther("4.5")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        await this.project.propose("first proposal", wei_of_05_ether, 10000);
        await this.project.approve_proposal(0, "owner's approval");
        await this.project.connect(investor).approve_proposal(0, "investor 's approval");
        await this.project.connect(contributor).request_payment(0, 0, 10000, "I have done the work");

        await this.project.connect(owner).approve_payment(0, 0, "owner's approval");
        await this.project.connect(investor).approve_payment(0, 0, "investor 's approval");

        assert.deepEqual(await this.token0.balanceOf(contributor.address), bigNumberify(wei_of_05_ether));
        assert.deepEqual(await this.token1.balanceOf(contributor.address), bigNumberify(wei_of_045_ether));

        assert.deepEqual(await this.token0.balanceOf(owner.address), bigNumberify(ethers.utils.parseEther("99999990")));
        assert.deepEqual(await this.token1.balanceOf(owner.address), bigNumberify(ethers.utils.parseEther("99999000.05")));

        assert.deepEqual(await this.token0.balanceOf(investor.address), bigNumberify(wei_of_4_5_ether));
        assert.deepEqual(await this.token1.balanceOf(investor.address), bigNumberify(ethers.utils.parseEther("999")));

        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(ethers.utils.parseEther("5")));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(ethers.utils.parseEther("0.5")));

        let own = await this.project._stake_holders(owner.address);
        assert.deepEqual (own[0], bigNumberify(ethers.utils.parseEther("5")));
        let inv = await this.project._stake_holders(investor.address);
        assert.deepEqual (inv[1], bigNumberify(ethers.utils.parseEther("0.5")));

        prop = await this.project._proposals(0);
        expect(prop[2]).to.equal(true);
        expect(prop[3]).to.equal(false);
        expect(prop[4]).to.equal(true);
    });


    it('can reject payment request', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")
        let wei_of_045_ether = ethers.utils.parseEther("0.45")
        let wei_of_4_5_ether = ethers.utils.parseEther("4.5")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        await this.project.propose("first proposal", wei_of_05_ether, 100000);
        await this.project.approve_proposal(0, "owner's approval");
        await this.project.connect(investor).approve_proposal(0, "investor 's approval");
        await this.project.connect(contributor).request_payment(0, 0, 1000, "I have done the work");

        await this.project.connect(owner).reject_payment(0, 0, "owner's rejection");

        let req = await this.project.get_request_info(0, 0);
        expect(req[2]).to.equal(false);
        expect(req[3]).to.equal(true);

    });


    it('can withdraw', async function () {
        const [owner, investor, contributor] = await ethers.getSigners();

        let wei_of_1000_ether = ethers.utils.parseEther("1000")
        let wei_of_10_ether = ethers.utils.parseEther("10")
        let wei_of_1_ether = ethers.utils.parseEther("1")
        let wei_of_05_ether = ethers.utils.parseEther("0.5")
        let wei_of_06_ether = ethers.utils.parseEther("0.6")
        let wei_of_4_5_ether = ethers.utils.parseEther("4.5")
        let wei_of_15_5_ether = ethers.utils.parseEther("15.5")

        await this.token1.connect(owner).transfer(investor.address, wei_of_1000_ether)
        await this.token0.connect(owner).approve(this.project.address, wei_of_1000_ether)
        await this.token1.connect(investor).approve(this.project.address, wei_of_1000_ether)

        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, 10, 90, 90, 10, "first project");
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        await this.project.connect(investor).deposit(this.token1.address, wei_of_1_ether);

        // lock the fund
        await this.project.propose("first proposal", wei_of_05_ether, 100000);
        await this.project.approve_proposal(0, "owner's approval");
        await this.project.connect(investor).approve_proposal(0, "investor 's approval");

        // withdraw 0.6 would not work 
        let throwed = false;
        try {
            await this.project.connect(investor).withdraw(0, wei_of_06_ether);
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);
        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(wei_of_10_ether));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(wei_of_1_ether));

        // withdraw 4.5 would not work
        throwed = false;
        try {
            await this.project.connect(owner).withdraw(wei_of_4_5_ether, 0);
        } catch (err) {
            throwed = true;
        }
        expect (throwed).to.equal(true);
        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(wei_of_10_ether));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(wei_of_1_ether));

        // make another deposit
        await this.project.connect(owner).deposit(this.token0.address, wei_of_10_ether);
        // withdraw 4.5 would work
        await this.project.connect(owner).withdraw(wei_of_4_5_ether, 0);
        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(wei_of_15_5_ether));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(wei_of_1_ether));

    });


    // TODO test proposal deadline
    // TODO test request deadline

});
