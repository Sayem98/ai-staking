// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Staking {
    uint256 public totalStaked;
    mapping(address => uint256) public staked;

    function stake(uint256 amount) public {
        staked[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint256 amount) public {
        require(staked[msg.sender] >= amount, "Insufficient staked amount");
        staked[msg.sender] -= amount;
        totalStaked -= amount;
    }
}
