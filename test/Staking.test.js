const { expect } = require("chai");

describe("Staking", function () {
  let owner, token, staking;

  beforeEach(async () => {
     [owner] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    const Staking = await ethers.getContractFactory("Stakings");

    token = await Token.deploy();
    staking = await Staking.deploy(token.target);
    
  });

  it("should create an offer", async () => {
    const duration = 3600; // 1 hour
    const rewardRate = 10;
    const minStake = 100;
    const description = "Offer - 1";

    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description, 2);
    await createOfferTx.wait();

    const [minStakeReturned, rewardRateReturned, durationReturned, descriptionReturned, amountStaked, rewardsDistributed, isActive] = await staking.stakingOffers(0);
    
    expect(minStakeReturned).to.equal(minStake);
    expect(rewardRateReturned).to.equal(rewardRate);
    expect(durationReturned).to.equal(duration);
    expect(descriptionReturned).to.equal(description);
  });

  it("should edit an offer", async () => {
    // Create an initial offer
    const duration = 3600; // 1 hour
    const rewardRate = 10;
    const minStake = 100;
    const description = "Offer - 1";

    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description, 2);
    await createOfferTx.wait();

    // Edit the offer
    const newDuration = 7200; // 2 hours
    const newRewardRate = 20;
    const newMinStake = 200;
    const newDescription = "Updated Offer - 1";

    const editOfferTx = await staking.editOffer(0, newMinStake, newRewardRate, newDuration, newDescription, 2);
    await editOfferTx.wait();

        const [minStakeReturned, rewardRateReturned, durationReturned, descriptionReturned, amountStaked, rewardsDistributed, isActive] = await staking.stakingOffers(0);

    
    expect(minStakeReturned).to.equal(newMinStake);
    expect(rewardRateReturned).to.equal(newRewardRate);
    expect(durationReturned).to.equal(newDuration);
    expect(descriptionReturned).to.equal(newDescription);
  });

  it("should do a stake of 100 tokens", async () => {
    expect(await token.balanceOf(owner.address)).to.equal("100000000000000000000000"); // checking balance of owner

    // create offer 
    await staking.createOffer('100000000000000000000', 10, 3600, "Offer - 1 ", 2);

    // approve staking contract to spend tokens
    await token.approve(staking.target, '100000000000000000000');

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal('100000000000000000000');
    const addresses = [];
    for (let i = 0; i < 10; i++) {
      addresses.push(ethers.Wallet.createRandom().address);
    }

    // stake tokens and use 10 diffrent address as referral 
    const stakeTx = await staking.stake(0, addresses);
    await stakeTx.wait();

    const offer = await staking.stakingOffers(0);
    expect(offer['5']).to.equal('100000000000000000000');
    // NOW CHECK THE BALANCE OF OWNER check for referral daily reward 
    const referralReward = await staking.getDailyReferralReward('0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2');
    console.log('Referral Reward:', referralReward.toString());

    // fast forword to 5.1 min
    await ethers.provider.send("evm_increaseTime", [5.1 * 60]);
    await ethers.provider.send("evm_mine");

    const referralRewardNow = await staking.getDailyReferralReward('0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2');
    console.log('Referral Reward Now:', referralRewardNow.toString());

    const referralRewardShouldBe = (0.027 * 21)/100;
    // convert to wei
    const referralRewardNowInEther = ethers.formatEther(referralRewardNow, 'ether');
  
  });

  it("should generate reward", async () => {
    expect(await token.balanceOf(owner.address)).to.equal("100000000000000000000000"); // checking balance of owner

    // create offer 
    await staking.createOffer('100000000000000000000', 10, 3600, "Offer - 1 ", 2);

    // approve staking contract to spend tokens
    await token.approve(staking.target, '100000000000000000000');

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal('100000000000000000000');

    // get 10 address
    const addresses = [];
    for (let i = 0; i < 10; i++) {
      addresses.push(ethers.Wallet.createRandom().address);
    }

    // stake tokens and use 10 diffrent address as referral 
    const stakeTx = await staking.stake(0, addresses);


    
    // check the reward
    for (let i = 0; i < 10; i++) {
      const referralReward = await staking.referrals(addresses[i]);
      console.log('Referral Reward:', referralReward.dailyReward.toString());
    }
    

    await stakeTx.wait();

    const offer = await staking.stakingOffers(0);
    expect(offer['5']).to.equal('100000000000000000000');
   
    const reward = await staking.getDailyStakeReward(0);

    const allReward = await staking.getAllStakeDailyReward(owner)
    console.log('All Reward at 0 days passed ->:',reward.toString(), allReward.toString());

    // fast forword to 5.1 min
    await ethers.provider.send("evm_increaseTime", [5.2 * 60]);
    await ethers.provider.send("evm_mine");
    console.log('day 1')
    const rewardNow = await staking.getDailyStakeReward(0);
    const allReward4 = await staking.getAllStakeDailyReward(owner)
    console.log('Reward After One day passed:', rewardNow.toString(), allReward4.toString());

    console.log('withdrawing reward now');
    const withdrawRewardTx = await staking.withdrawReward(0);
    await withdrawRewardTx.wait();
    console.log('withdrawn complete');


    // fast forword to 5.1 min
    await ethers.provider.send("evm_increaseTime", [5.2 * 60]);
    await ethers.provider.send("evm_mine");

    console.log('Day 2')

    const rewardNow2 = await staking.getDailyStakeReward(0);
    const allReward6 = await staking.getAllStakeDailyReward(owner)
    console.log('Reward  after 2 days passed:', rewardNow2.toString(), allReward6.toString());

    console.log('withdrawing reward now day 2');
    const withdrawRewardTx2 = await staking.withdrawReward(0);
    const recepit2 = await withdrawRewardTx2.wait();

    console.log('withdrawn complete day 2');

    // fast forword to 1 hours
    await ethers.provider.send("evm_increaseTime", [3660]);
    await ethers.provider.send("evm_mine");

    // reward
    const rewardNow3 = await staking.getDailyStakeReward(0);
    console.log('Reward after staking hour days passed:', rewardNow3.toString());



  
  });

  // it('Should unstake', async () => {
  //   expect(await token.balanceOf(owner.address)).to.equal("100000000000000000000000"); // checking balance of owner

  //   // create offer 
  //   await staking.createOffer('100000000000000000000', 10, 3600, "Offer - 1 ", 2);

  //   // approve staking contract to spend tokens
  //   await token.approve(staking.target, '100000000000000000000');

  //   // check allowance
  //   expect(await token.allowance(owner.address, staking.target)).to.equal('100000000000000000000');
  //   let addresses = [];
  //   for (let i = 0; i < 10; i++) {
  //     addresses.push(ethers.Wallet.createRandom().address);
  //   }

  //   // stake tokens and use 10 diffrent address as referral 
  //   const stakeTx = await staking.stake(0, addresses);


  //   // fast forword to 1 hour
  //   await ethers.provider.send("evm_increaseTime", [3600]);
  //   await ethers.provider.send("evm_mine");

  //   // send token to the contract
  //   await token.transfer(staking.target, '100000000000000000000');

  //   // unstake
  //   const unstakeTx = await staking.unstake(0);
  //   await unstakeTx.wait();

  //   // claim reward
  //   const claimTx = await staking.withdrawReward(0);
  //   await claimTx.wait();
  //   console.log('Claimed Reward');

  //   // unstake
  //   // const unstakeTx = await staking.unstakeAll();

  //   const getStake = await staking.stakings(0);
  //   console.log('Stake:', getStake);
    

  // })

  
});
