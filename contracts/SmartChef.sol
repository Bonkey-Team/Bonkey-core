// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './abstracts/Ownable.sol';
import './libraries/SafeBEP20.sol';

contract SmartChef is Ownable {
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BNKYs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BNKYs distribution occurs.
        uint256 accBnkyPerShare; // Accumulated BNKYs per share, times 1e12. See below.
    }

    // The BNKY TOKEN!
    IBEP20 public banana;
    IBEP20 public rewardToken;

    // uint256 public maxStaking;

    // BNKY tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint;
    // The block number when BNKY mining starts.
    uint256 public startBlock;
    // The block number when BNKY mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    function initialize (
    ) public initializer {
        banana = IBEP20(0xAdc8e9B18b671DF686acCe0543F086293f2ef886);
        rewardToken = IBEP20(0xAdc8e9B18b671DF686acCe0543F086293f2ef886);
        rewardPerBlock = 50000000000000000;
        startBlock = 6623935;
        bonusEndBlock = 9215935;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: banana,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accBnkyPerShare: 0
        }));

        totalAllocPoint = 1000;
        // maxStaking = 50000000000000000000;
        __Ownable_init();
    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accBnkyPerShare = pool.accBnkyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 bnkyReward = multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
            accBnkyPerShare = accBnkyPerShare + (bnkyReward * 1e12 / lpSupply);
        }
        return (user.amount * accBnkyPerShare / 1e12) - user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 bnkyReward = multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accBnkyPerShare = pool.accBnkyPerShare + (bnkyReward * 1e12 / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake BANANA tokens to SmartChef
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        // require (_amount.add(user.amount) <= maxStaking, 'exceed max stake');

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accBnkyPerShare / 1e12) - user.rewardDebt;
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = user.amount * pool.accBnkyPerShare / 1e12;

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw BANANA tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = (user.amount * pool.accBnkyPerShare / 1e12) - user.rewardDebt;
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount * pool.accBnkyPerShare / 1e12;

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

}
