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


    function e2w(num_in_ether) {
        return ethers.utils.parseEther(num_in_ether);
    }

    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }


    it('give toke share to michael and jackie', async function () {
        const [owner, michael, jackie] = await ethers.getSigners();
        await this.token0.connect(owner).approve(this.project.address, e2w('21000000'))
        await this.token1.connect(owner).approve(this.project.address, e2w('21000000'))
        await this.project.connect(owner).initiate(this.token0.address,
            this.token1.address, e2w('1.0'), e2w('0.9'), e2w('0.9'), e2w('1.0'), "Founder release");

        await this.project.connect(owner).deposit(this.token0.address, e2w('21000000'));
        await this.project.connect(owner).deposit(this.token1.address, e2w('21000000'));

        await this.project.propose("Michael's share", e2w('20000000'), 10000000);
        await this.project.propose("Jackie's share", e2w('1000000'), 10000000);

        // michael
        await this.project.approve_proposal(0, "owner's approval");
        prop = await this.project._proposals(0);
        assert.deepEqual(prop[5], bigNumberify(e2w('42000000')));
        expect(prop[2]).to.equal(true);
        expect(prop[3]).to.equal(false);
        expect(prop[4]).to.equal(false);

        await this.project.connect(michael).request_payment(0, 10000000, "I am michael");
        await this.project.connect(owner).approve_payment(0, 0, "owner's approval");

        assert.deepEqual(await this.token0.balanceOf(michael.address), bigNumberify(e2w('20000000')));
        assert.deepEqual(await this.token1.balanceOf(michael.address), bigNumberify(e2w('0')));

        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(ethers.utils.parseEther("1000000")));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(ethers.utils.parseEther("1000000")));

        // jackie
        await this.project.approve_proposal(1, "owner's approval");
        prop = await this.project._proposals(1);
        assert.deepEqual(prop[5], bigNumberify(e2w('2000000')));
        expect(prop[2]).to.equal(true);
        expect(prop[3]).to.equal(false);
        expect(prop[4]).to.equal(false);

        await this.project.connect(jackie).request_payment(1, 10000000, "I am michael");
        await this.project.connect(owner).approve_payment(1, 0, "owner's approval");

        assert.deepEqual(await this.token0.balanceOf(jackie.address), bigNumberify(e2w('1000000')));
        assert.deepEqual(await this.token1.balanceOf(jackie.address), bigNumberify(e2w('0')));


        assert.deepEqual(await this.project._tot_source_contribution(), bigNumberify(ethers.utils.parseEther("0")));
        assert.deepEqual(await this.project._tot_target_contribution(), bigNumberify(ethers.utils.parseEther("0")));
    });

    it('bonkey raise fund', async function () {
        const accounts = await ethers.getSigners();

        await this.token0.connect(accounts[0]).approve(this.project.address, e2w('1000000'))
        await this.token1.connect(accounts[0]).approve(this.project.address, e2w('1000000'))
        for (let i= 1; i<20; i++) {
            await this.token0.connect(accounts[0]).transfer(accounts[i].address, e2w('100000'))
            await this.token1.connect(accounts[0]).transfer(accounts[i].address, e2w('100000'))
            await this.token0.connect(accounts[i]).approve(this.project.address, e2w('100000'))
            await this.token1.connect(accounts[i]).approve(this.project.address, e2w('100000'))
        }

        await this.project.connect(accounts[0]).initiate(this.token0.address,
            this.token1.address, e2w('1.0'), e2w('0.9'), e2w('0.9'), e2w('0.2'), "Bonkey raise fund");

        await this.project.connect(accounts[0]).deposit(this.token0.address, e2w('100000'));
        for (let i=0; i<10; i++) {
            await this.project.connect(accounts[i]).deposit(this.token0.address, e2w('100000'));
        }
        await this.project.connect(accounts[0]).deposit(this.token1.address, e2w('100000'));
        for (let i=10; i<20; i++) {
            await this.project.connect(accounts[i]).deposit(this.token1.address, e2w('100000'));
        }

        await this.project.propose("NFT raise fund", e2w('500000'), 10000000);
        await this.project.propose("Yield farm raise fund", e2w('500000'), 10000000);

        for (let i=0; i<9; i++) {
            await this.project.connect(accounts[i]).approve_proposal(0, 'approval');
            await this.project.connect(accounts[i]).approve_proposal(1, 'approval');
        }
        for (let i=10; i<19; i++) {
            await this.project.connect(accounts[i]).approve_proposal(0, 'approval');
            await this.project.connect(accounts[i]).approve_proposal(1, 'approval');
        }

        await this.project.connect(accounts[0]).request_payment(0, 10000000, "get fund");
        for (let i=0; i<18; i++) {
            await this.project.connect(accounts[i]).approve_payment(0, 0, "payment approval");
        }

        await this.project.connect(accounts[0]).request_payment(1, 10000000, "get fund");
        for (let i=0; i<18; i++) {
            await this.project.connect(accounts[i]).approve_payment(1, 0, "payment approval");
        }

        
        let remain_t0 = await this.project._tot_source_contribution()
        let remain_t1 = await this.project._tot_target_contribution()
        for (let i=0; i<20; i++) {
            let t0 = await this.token0.balanceOf(accounts[i].address)
            let t1 = await this.token1.balanceOf(accounts[i].address)
            console.log(t0)
            console.log(t1)
        }
        console.log(remain_t0)
        console.log(remain_t1)
    });

});
