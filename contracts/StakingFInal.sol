//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/Staking.sol

contract StakingsFinal is Ownable {
    struct StakingOffer {
        uint amount;
        uint apy;
        uint lockPeriod;
        string name;
        uint numberOfStakers;
        uint totalStaked;
        bool isActive;
    }
    struct Staking {
        uint id;
        uint amount;
        uint lastClaminedTime;
        uint unstakeTime;
        address staker;
        uint bonus;
    }

    struct Referral {
        uint rewardClaimed;
        uint lastClaimedTime;
        uint dailyReward;
    }

    StakingOffer[] public stakingOffers;

    mapping(uint => Staking) public stakings;
    mapping(address => uint[]) public usersStakeids;

    uint public numberOfStakes;

    IERC20 public token;

    //referral
    uint[5] public referralRewardPercentages = [10, 5, 3, 2, 1];
    uint[5] public referralDailyRewardPercentages = [10, 5, 3, 2, 1];
    bool public isEnabledReferral = true;
    bool public isEnabledDailyReferralReward;
    mapping(address => Referral) public referrals;

    // unstake
    bool public isEnabledUnstakeFee = true;
    uint public unstakeFeePercentage = 10;

    // events
    event Staked(address indexed staker, uint indexed id, uint amount);
    event Unstaked(address indexed staker, uint indexed id, uint amount);
    event Claimed(address indexed staker, uint indexed id, uint amount);
    event OfferCreated(
        uint indexed id,
        uint amount,
        uint apy,
        uint lockPeriod,
        string name
    );
    event OfferEdited(
        uint indexed id,
        uint amount,
        uint apy,
        uint lockPeriod,
        string name
    );

    constructor(address _token) {
        token = IERC20(_token);
    }

    /*
        @des function to create a new offer. Only owner can create a new offer.
        @params
            _amount: amount of the token that is being staked.
            _apy: APY of the stake.
            _lockPeriod: lock period of the stake.
            _name: name of the stake.
     */
    function createOffer(
        uint _amount,
        uint _apy,
        uint _lockPeriod,
        string memory _name
    ) external onlyOwner {
        stakingOffers.push(
            StakingOffer({
                amount: _amount,
                apy: _apy,
                lockPeriod: _lockPeriod,
                name: _name,
                totalStaked: 0,
                numberOfStakers: 0,
                isActive: true
            })
        );
        emit OfferCreated(
            stakingOffers.length - 1,
            _amount,
            _apy,
            _lockPeriod,
            _name
        );
    }

    /*
        @des function to edit offer.
        @params
            _id: id of the offer.
            _amount: amount of the token that is being staked.
            _apy: APY of the stake.
            _lockPeriod: lock period of the stake.
            _name: name of the stake.
     */

    function editOffer(
        uint _id,
        uint _amount,
        uint _apy,
        uint _lockPeriod,
        string memory _name
    ) external onlyOwner {
        stakingOffers[_id].amount = _amount;
        stakingOffers[_id].apy = _apy;
        stakingOffers[_id].lockPeriod = _lockPeriod;
        stakingOffers[_id].name = _name;

        emit OfferEdited(_id, _amount, _apy, _lockPeriod, _name);
    }

    /*
        @des function to stake tokens.
        @params
            _id: id of the offer.
            _amount: amount of the token that is being staked.
            _referrer: address of the referrer. array of address of the referrer 5.
     */

    function stake(
        uint _id,
        uint _amount,
        address[5] memory _referrer
    ) external {
        require(stakingOffers[_id].isActive, "Offer is not active");
        require(
            _amount >= stakingOffers[_id].amount,
            "Amount is less than required"
        );
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        stakingOffers[_id].totalStaked += _amount;
        // number of unique stakers
        stakingOffers[_id].numberOfStakers += 1;

        // if referral is enabled
        if (isEnabledReferral) {
            for (uint i = 0; i < 5; i++) {
                if (_referrer[i] != address(0)) {
                    uint reward = (_amount * referralRewardPercentages[i]) /
                        100;
                    require(
                        token.transfer(_referrer[i], reward),
                        "Token transfer failed"
                    );

                    referrals[_referrer[i]]
                        .dailyReward += calculateDailyReferralReward(
                        _amount,
                        stakingOffers[_id].apy,
                        referralDailyRewardPercentages[i]
                    );
                }
            }
        }

        stakings[numberOfStakes] = Staking({
            id: _id,
            amount: _amount,
            lastClaminedTime: block.timestamp,
            unstakeTime: block.timestamp + stakingOffers[_id].lockPeriod,
            staker: msg.sender,
            bonus: 0
        });

        usersStakeids[msg.sender].push(numberOfStakes);

        emit Staked(msg.sender, numberOfStakes, _amount);

        numberOfStakes += 1;
    }

    /*
        @des function to add  stake by owner only.
        @params
            _id: id of the offer.
            _amount: amount of the token that is being staked.
            _staker: address of the staker.
            
     */

    function addStake(
        uint _id,
        uint _amount,
        address _staker
    ) external onlyOwner {
        require(stakingOffers[_id].isActive, "Offer is not active");
        require(
            _amount >= stakingOffers[_id].amount,
            "Amount is less than required"
        );

        stakingOffers[_id].totalStaked += _amount;
        // number of unique stakers
        stakingOffers[_id].numberOfStakers += 1;

        stakings[numberOfStakes] = Staking({
            id: _id,
            amount: _amount,
            lastClaminedTime: block.timestamp,
            unstakeTime: block.timestamp + stakingOffers[_id].lockPeriod,
            staker: _staker,
            bonus: 0
        });

        usersStakeids[_staker].push(numberOfStakes);

        emit Staked(_staker, numberOfStakes, _amount);
    }

    /*
        @des function to add multiple stake by owner only.
        @params
            _id[]: id of the offer.
            _amount[]: amount of the token that is being staked.
            _staker[]: address of the staker.
            
            
     */

    function addMultipleStake(
        uint[] memory _id,
        uint[] memory _amount,
        address[] memory _staker
    ) external onlyOwner {
        require(_id.length == _amount.length, "Invalid input");
        require(_id.length == _staker.length, "Invalid input");

        for (uint i = 0; i < _id.length; i++) {
            if (stakingOffers[_id[i]].isActive) {
                continue;
            }
            if (_amount[i] >= stakingOffers[_id[i]].amount) {
                continue;
            }

            stakingOffers[_id[i]].totalStaked += _amount[i];
            // number of unique stakers
            stakingOffers[_id[i]].numberOfStakers += 1;

            stakings[numberOfStakes] = Staking({
                id: _id[i],
                amount: _amount[i],
                lastClaminedTime: block.timestamp,
                unstakeTime: block.timestamp + stakingOffers[_id[i]].lockPeriod,
                staker: _staker[i],
                bonus: 0
            });

            usersStakeids[_staker[i]].push(numberOfStakes);

            emit Staked(_staker[i], numberOfStakes, _amount[i]);
        }
    }

    /*
        @des function to unstake tokens.
        @params
            _id: id of the stake.
     */

    function unstake(uint _id) external {
        require(
            stakings[_id].staker == msg.sender,
            "You are not the staker of this stake"
        );
        // unstake time is premature
        if (stakings[_id].unstakeTime > block.timestamp) {
            uint amount = stakings[_id].amount;
            if (isEnabledUnstakeFee) {
                uint fee = (amount * unstakeFeePercentage) / 100;
                amount -= fee;
                require(token.transfer(owner(), fee), "Token transfer failed");
            }

            require(
                token.transfer(msg.sender, amount),
                "Token transfer failed"
            );

            emit Unstaked(msg.sender, _id, amount);
        } else {
            // unstake time passed sent all token

            // calculate reward also
            uint dayPassed = daysPassed(_id);
            uint reward = calculateReward(
                stakings[_id].amount,
                stakingOffers[stakings[_id].id].apy,
                dayPassed
            );

            require(
                token.transfer(msg.sender, stakings[_id].amount + reward),
                "Token transfer failed"
            );

            emit Unstaked(msg.sender, _id, stakings[_id].amount + reward);
        }
    }

    /*
        @des function to unstake all stakes of msg.sender
        @params
            
     */

    function unstakeAll() external {
        uint totalAmount = 0;
        for (uint i = 0; i < usersStakeids[msg.sender].length; i++) {
            uint id = usersStakeids[msg.sender][i];
            if (stakings[id].unstakeTime < block.timestamp) {
                uint amount = stakings[id].amount;
                if (isEnabledUnstakeFee) {
                    uint fee = (amount * unstakeFeePercentage) / 100;
                    amount -= fee;
                    require(
                        token.transfer(owner(), fee),
                        "Token transfer failed"
                    );
                }

                totalAmount += amount;
                emit Unstaked(msg.sender, id, amount);
            } else {
                // unstake time passed sent all token

                // calculate reward also
                uint dayPassed = daysPassed(id);
                uint reward = calculateReward(
                    stakings[id].amount,
                    stakingOffers[stakings[id].id].apy,
                    dayPassed
                );
                totalAmount += stakings[id].amount + reward;
                emit Unstaked(msg.sender, id, stakings[id].amount + reward);
            }
        }

        require(
            token.transfer(msg.sender, totalAmount),
            "Token transfer failed"
        );
    }

    /*
        @des function to claim rewards.
        @params
            _id: id of the stake.
     */

    function withdrawReward(uint _id) external {
        require(
            stakings[_id].staker == msg.sender,
            "You are not the staker of this stake"
        );

        uint dayPassed = daysPassed(_id);
        uint reward = calculateReward(
            stakings[_id].amount,
            stakingOffers[stakings[_id].id].apy,
            dayPassed
        );

        require(token.transfer(msg.sender, reward), "Token transfer failed");

        emit Claimed(msg.sender, _id, reward);

        stakings[_id].lastClaminedTime = block.timestamp;
    }

    /*
        @des function to enable calculate all rewards of the msg.sender.
            
     */
    function claimAllRewards() external {
        uint totalRewards = 0;
        for (uint i = 0; i < usersStakeids[msg.sender].length; i++) {
            uint id = usersStakeids[msg.sender][i];
            uint dayPassed = daysPassed(id);
            uint reward = calculateReward(
                stakings[id].amount,
                stakingOffers[stakings[id].id].apy,
                dayPassed
            );

            totalRewards += reward;

            emit Claimed(msg.sender, id, reward);

            stakings[id].lastClaminedTime = block.timestamp;
        }

        require(
            token.transfer(msg.sender, totalRewards),
            "Token transfer failed"
        );
        emit Claimed(msg.sender, 0, totalRewards);
    }

    /*
        @des function to add bonus.
        @params
            _id: id of the stake.
            _amount: amount of the bonus.
     */

    function addBonus(uint _id, uint _amount) external onlyOwner {
        require(
            stakings[_id].staker != address(0),
            "Stake does not exist with this id"
        );
        require(
            token.transferFrom(owner(), address(this), _amount),
            "Token transfer failed"
        );

        stakings[_id].bonus += _amount;
    }

    /*
        @des function to add multiple bonus.
        @params
            _id: id of the stake.
            _amount: amount of the bonus.
     */

    function addMultipleBonus(
        uint[] memory _ids,
        uint[] memory _amounts
    ) external onlyOwner {
        require(_ids.length == _amounts.length, "Invalid input");
        uint totalAmount = 0;
        for (uint i = 0; i < _ids.length; i++) {
            require(
                stakings[_ids[i]].staker != address(0),
                "Stake does not exist with this id"
            );
            totalAmount += _amounts[i];
            stakings[_ids[i]].bonus += _amounts[i];
        }

        require(
            token.transferFrom(owner(), address(this), totalAmount),
            "Token transfer failed"
        );
    }

    /*
        @des function to claim bonus.
        @params
            _id: id of the stake.
     */

    function claimBonus(uint _id) external {
        require(
            stakings[_id].staker == msg.sender,
            "You are not the staker of this stake"
        );

        require(
            token.transfer(msg.sender, stakings[_id].bonus),
            "Token transfer failed"
        );

        emit Claimed(msg.sender, _id, stakings[_id].bonus);

        stakings[_id].bonus = 0;
    }

    /*
        @des function to claim all bonus.
        @params
            _id: id of the stake.
     */

    function claimAllBonus() external {
        uint totalBonus = 0;
        for (uint i = 0; i < usersStakeids[msg.sender].length; i++) {
            uint id = usersStakeids[msg.sender][i];
            totalBonus += stakings[id].bonus;

            emit Claimed(msg.sender, id, stakings[id].bonus);

            stakings[id].bonus = 0;
        }

        require(
            token.transfer(msg.sender, totalBonus),
            "Token transfer failed"
        );
        emit Claimed(msg.sender, 0, totalBonus);
    }

    function claimReferralBonus() external {
        require(
            isEnabledDailyReferralReward,
            "Daily referral reward is not enabled"
        );

        uint _daysPassedReferral = daysPassedReferral(msg.sender);
        require(_daysPassedReferral > 0, "You have already claimed today");

        uint totalReward = _daysPassedReferral *
            referrals[msg.sender].dailyReward;
        require(
            token.transfer(msg.sender, totalReward),
            "Token transfer failed"
        );

        emit Claimed(msg.sender, 0, totalReward);
    }

    /*
        @des function to calculate days passed.
        @params
            _id: id of the stake.
     */

    function daysPassed(uint _id) public view returns (uint) {
        return (block.timestamp - stakings[_id].lastClaminedTime) / 1 days;
    }

    /*
        @des function to calculate referral days passed.
        @params
            _id: id of the stake.
     */

    function daysPassedReferral(address _referral) public view returns (uint) {
        return
            (block.timestamp - referrals[_referral].lastClaimedTime) / 1 days;
    }

    /*
        @des function calculate reward based on apy per year.
        @params
            _amount: amount of the token that is being staked.
            _apy: APY of the stake.
            _days: number of days.
     */

    function calculateReward(
        uint _amount,
        uint _apy,
        uint _days
    ) public pure returns (uint) {
        return (_amount * _apy * _days) / (100 * 365);
    }

    /*
        @des function calculate daily referral reward based on apy per year.
        @params
            _amount: amount of the token that is being staked.
            _apy: APY of the stake.
     */

    function calculateDailyReferralReward(
        uint _amount,
        uint _apy,
        uint _percentage
    ) public pure returns (uint) {
        return ((((_amount * _apy) / 100) * 365) * _percentage) / 100;
    }

    /*
        @des function to enable referral.
     */

    function enableReferral() external onlyOwner {
        isEnabledReferral = true;
    }

    /*
        @des function to disable referral.
     */

    function disableReferral() external onlyOwner {
        isEnabledReferral = false;
    }

    /*
        @des function to enable daily referral reward.
     */

    function enableDailyReferralReward() external onlyOwner {
        isEnabledDailyReferralReward = true;
    }

    /*
        @des function to disable daily referral reward.
     */

    function disableDailyReferralReward() external onlyOwner {
        isEnabledDailyReferralReward = false;
    }

    /*
        @des function to enable unstake fee.
     */

    function enableUnstakeFee() external onlyOwner {
        isEnabledUnstakeFee = true;
    }

    /*
        @des function to disable unstake fee.
     */

    function disableUnstakeFee() external onlyOwner {
        isEnabledUnstakeFee = false;
    }

    /*
        @des function to set unstake fee percentage.
        @params
            _percentage: percentage of the fee.
     */

    function setUnstakeFeePercentage(uint _percentage) external onlyOwner {
        unstakeFeePercentage = _percentage;
    }

    /*
        @des function to set referral reward percentages.
        @params
            _percentages: array of percentage of the reward.
     */

    function setReferralRewardPercentages(
        uint[5] memory _percentages
    ) external onlyOwner {
        referralRewardPercentages = _percentages;
    }
}
