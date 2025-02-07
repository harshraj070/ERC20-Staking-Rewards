//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract StakingToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public baseApy = 10;
    uint256 public rewardRate = 1e18;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor() ERC20("StakeToken", "STK") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function stake(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _transfer(msg.sender, address(this), _amount);

        if (stakes[msg.sender].amount == 0) {
            stakes[msg.sender] = Stake(_amount, block.timestamp);
        } else {
            rewards[msg.sender] += calculateReward(msg.sender);
            stakes[msg.sender].amount += _amount;
            stakes[msg.sender].timestamp = block.timestamp;
        }

        totalStaked += _amount;
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        require(
            stakes[msg.sender].amount >= _amount,
            "Insufficient staked amount"
        );
        rewards[msg.sender] += calculateReward(msg.sender);

        stakes[msg.sender].amount -= _amount;

        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() external {
        uint256 reward = rewards[msg.sender] + calculateReward(msg.sender);
        require(reward > 0, "No rewards available");

        rewards[msg.sender] = 0;
        stakes[msg.sender].timestamp = block.timestamp;
        _mint(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        Stake memory userStake = stakes[_user];
        if (userStake.amount == 0) return 0;

        uint256 stakeDuration = block.timestamp - userStake.timestamp;
        uint256 dynamicApy = baseApy * (1e18 - (totalStaked / INITIAL_SUPPLY));
        return
            (userStake.amount * dynamicApy * stakeDuration) / (365 days * 100);
    }
}
