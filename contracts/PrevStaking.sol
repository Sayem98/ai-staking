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

contract Stakings is Ownable {
    struct Offer {
        IERC20 token; // token that users will use to stake
        uint apy;
        uint lockPeriod; // lock periods
        bool isActive;
        string name;
        uint numberOfStakers;
        uint tvl;
        uint rewardPool; // total reward pool for staking.
        string bannerUrl;
        string logourl;
    }
    struct Staking {
        uint id; // offer id
        uint amount;
        uint lastClaminedTime;
        uint unstakeTime;
        address staker;
    }

    mapping(uint => Offer) public offers;

    mapping(uint => Staking) public stakings;

    mapping(address => uint[]) public usersStakeids;

    uint public numberOfOffers;
    uint public numberOfStakes;

    /*
        @des function to create a new offer.
        @params _token: address of the token that is besing staked. 
                _apy: APY of the stake
                _lockPeriod: lockperiod of the stake.
                _isActivated: for storing status of offers.
    
     */
    function createOffer(
        address _token,
        uint _apy,
        uint _lockPeriod,
        bool _isActive,
        string memory _name,
        uint _rewardPool,
        string memory _bannerUrl,
        string memory _logoUrl
    ) external onlyOwner {
        numberOfOffers = numberOfOffers + 1;
        Offer storage _offer = offers[numberOfOffers];
        _offer.apy = _apy;
        _offer.token = IERC20(_token);
        _offer.lockPeriod = _lockPeriod;
        _offer.isActive = _isActive;
        _offer.name = _name;
        _offer.rewardPool = _rewardPool;
        _offer.token.transferFrom(msg.sender, address(this), _rewardPool);
        _offer.bannerUrl = _bannerUrl;
        _offer.logourl = _logoUrl;
    }

    /*
        @des function to edit offer.
        @params _token: address of the token that is besing staked. 
                _apy: APY of the stake
                _lockPeriod: lockperiod of the stake.
                _isActivated: for storing status of offers.
                _id: id of the offer.
    
     */
    function editOffer(
        uint _id,
        address _token,
        uint _apy,
        uint _lockPeriod,
        bool _isActivate,
        uint _rewardPool
    ) external onlyOwner {
        require(_id > 0 && _id <= numberOfOffers, "Offer does not exist");
        numberOfOffers = numberOfOffers + 1;
        Offer storage _offer = offers[numberOfOffers];
        _offer.apy = _apy;
        _offer.token = IERC20(_token);
        _offer.lockPeriod = _lockPeriod;
        _offer.isActive = _isActivate;
        if (_rewardPool != 0) {
            _offer.rewardPool += _rewardPool;
            _offer.token.transferFrom(msg.sender, address(this), _rewardPool);
        }
    }

    function stake(uint _id, uint _amount) external {
        require(_id > 0 && _id <= numberOfOffers, "Offer does not exist");
        require(offers[_id].rewardPool > 0, "Reward Pool is 0");
        numberOfStakes = numberOfStakes + 1;
        Staking storage myStake = stakings[numberOfStakes];
        IERC20 _token = offers[_id].token;
        _token.transferFrom(msg.sender, address(this), _amount);
        myStake.amount = _amount;
        myStake.id = _id;
        myStake.unstakeTime = block.timestamp + offers[_id].lockPeriod;
        myStake.lastClaminedTime = block.timestamp;
        myStake.staker = msg.sender;
        offers[_id].tvl += _amount;
        usersStakeids[msg.sender].push(numberOfStakes);
        offers[_id].numberOfStakers++;
    }

    function unStake(uint _stakeId) external {
        require(
            _stakeId > 0 && _stakeId <= numberOfStakes,
            "Stake does not exist"
        );
        Staking storage myStake = stakings[_stakeId];
        uint _amount = myStake.amount;
        myStake.amount = 0;
        // check if unstake time has passed.
        if (myStake.unstakeTime > block.timestamp) {
            // cut 20% of the stake and send to staker.
            _amount = (_amount * 80) / 100;
        }
        IERC20 _token = offers[myStake.id].token;
        _token.transfer(msg.sender, _amount);
    }

    function claimReward(uint _stakeId) external {
        require(
            _stakeId > 0 && _stakeId <= numberOfStakes,
            "Stake does not exist"
        );
        Staking storage myStake = stakings[_stakeId];
        IERC20 _token = offers[myStake.id].token;
        uint _reward = reward(_stakeId);
        require(
            offers[myStake.id].rewardPool >= _reward,
            "There are no rewards to give"
        );
        offers[myStake.id].rewardPool -= _reward;
        myStake.lastClaminedTime = block.timestamp;
        _token.transfer(myStake.staker, _reward);
    }

    function timePassed(uint _stakeId) public view returns (uint) {
        Staking memory myStake = stakings[_stakeId];
        return block.timestamp - myStake.lastClaminedTime;
    }

    function reward(uint _stakeId) public view returns (uint) {
        Staking memory myStake = stakings[_stakeId];
        uint _offerId = myStake.id;
        Offer memory _offer = offers[_offerId];
        uint _apy = _offer.apy;
        uint _totalReward = (myStake.amount * _apy) / 100;
        // reward/second.
        uint _timepassed = timePassed(_stakeId);
        uint _rewardPerSecond = _totalReward / 31_536_000;
        if (_offer.rewardPool < _rewardPerSecond * _timepassed) {
            return _offer.rewardPool;
        } else {
            return _rewardPerSecond * _timepassed;
        }
    }

    function withdrawToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawNative() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getMyStakeIds() public view returns (uint[] memory) {
        return usersStakeids[msg.sender];
    }
}
