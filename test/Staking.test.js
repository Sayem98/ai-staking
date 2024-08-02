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

    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description);
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

    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description);
    await createOfferTx.wait();

    // Edit the offer
    const newDuration = 7200; // 2 hours
    const newRewardRate = 20;
    const newMinStake = 200;
    const newDescription = "Updated Offer - 1";

    const editOfferTx = await staking.editOffer(0, newMinStake, newRewardRate, newDuration, newDescription);
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
    await staking.createOffer('100000000000000000000', 10, 3600, "Offer - 1 ");

    // approve staking contract to spend tokens
    await token.approve(staking.target, '100000000000000000000');

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal('100000000000000000000');

    // stake tokens
    const stakeTx = await staking.stake(0, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
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
    await staking.createOffer('100000000000000000000', 10, 3600, "Offer - 1 ");

    // approve staking contract to spend tokens
    await token.approve(staking.target, '100000000000000000000');

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal('100000000000000000000');

    // stake tokens
    const stakeTx = await staking.stake(0, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    const offer = await staking.stakingOffers(0);
    expect(offer['5']).to.equal('100000000000000000000');
   
    const reward = await staking.getDailyStakeReward(0);

    const allReward = await staking.getAllStakeDailyReward(owner)
    expect(reward).to.equal(allReward);

    // fast forword to 5.1 min
    await ethers.provider.send("evm_increaseTime", [5.1 * 60]);
    await ethers.provider.send("evm_mine");

    const rewardNow = await staking.getDailyStakeReward(0);
    const allReward2 = await staking.getAllStakeDailyReward(owner)
    expect(rewardNow).to.equal(allReward2);

    const withdrawRewardTx = await staking.claimAllRewards();
    
    await withdrawRewardTx.wait();

    const rewardNowW = await staking.getDailyStakeReward(0);
    const allReward2w = await staking.getAllStakeDailyReward(owner)
    console.log('Reward Now after cmaiming:', rewardNowW.toString());
    expect(rewardNowW).to.equal(allReward2w);
    // fast forword to 5.1 min
    await ethers.provider.send("evm_increaseTime", [5.1 * 60]);
    await ethers.provider.send("evm_mine");

    const rewardNow2 = await staking.getDailyStakeReward(0);

    const allReward3 = await staking.getAllStakeDailyReward(owner)

    expect(rewardNow2).to.equal(allReward3);

  
  });

  
});
