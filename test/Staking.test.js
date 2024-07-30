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
    await staking.createOffer(100, 10, 3600, "Offer - 1 ");

    // approve staking contract to spend tokens
    await token.approve(staking.target, "100");

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal("100");

    // stake tokens
    const stakeTx = await staking.stake(0, 100, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    const offer = await staking.stakingOffers(0);
    expect(offer['5']).to.equal("100");
  });

  it('should do a premature unstake', async () => {
    // create offer 
    await staking.createOffer(100, 10, 3600, "Offer - 1 ");
     // amount in wei
    const stakeAmount = ethers.parseEther("100", 'ether');
    // approve staking contract to spend tokens
    await token.approve(staking.target, stakeAmount);

    // transfer tokens to staking contract from owner address
    await token.transfer(staking.target, ethers.parseEther("10000", 'ether'));


    let balance = await token.balanceOf(owner.address);
    // from wei to ether
    
    balance = Number(ethers.formatEther(balance, 'ether'))-100;
    // stake tokens
    const stakeTx = await staking.stake(0, stakeAmount, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    // premature unstake
    const unstakeTx = await staking.unstake(0);
    await unstakeTx.wait();

    // Add assertions to verify the state after unstaking
    expect(await token.balanceOf(owner.address)).to.equal(ethers.parseEther((balance + 100).toString(), 'ether')); // adjust the expected balance accordingly
    
  });

  it('should do a mature unstake', async () => {
    // create offer 
    await staking.createOffer(100, 10, 3600, "Offer - 1 ");
     // amount in wei
    const stakeAmount = ethers.parseEther("100", 'ether');
    // approve staking contract to spend tokens
    await token.approve(staking.target, stakeAmount);

    // transfer tokens to staking contract from owner address
    await token.transfer(staking.target, ethers.parseEther("10000", 'ether'));


    let balance = await token.balanceOf(owner.address);
    // from wei to ether
    
    balance = Number(ethers.formatEther(balance, 'ether'))-100;
    // stake tokens
    const stakeTx = await staking.stake(0, stakeAmount, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    // Fast forward time by 1 hour
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    // premature unstake
    const unstakeTx = await staking.unstake(0);
    await unstakeTx.wait();

    // Add assertions to verify the state after unstaking
    expect(await token.balanceOf(owner.address)).to.equal(ethers.parseEther((balance + 100).toString(), 'ether')); // adjust the expected balance accordingly
    
  });

  it("should add a single stake to an existing offer", async () => {
    const duration = 3600; // 1 hour
    const rewardRate = 10;
    const minStake = 100;
    const description = "Offer - 1";

    const createOfferTx = await staking.createOffer(BigInt(100), rewardRate, duration, description);
    await createOfferTx.wait();

    await token.approve(staking.target, "200");

    const stakeTx = await staking.stake(0, BigInt(100), [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    const [amountStaked,, , , ,] = await staking.stakingOffers(0);
    expect(amountStaked).to.equal(BigInt(100));
  });

  it("should add multiple stakes to an existing offer", async () => {
    const duration = 3600; // 1 hour
    const rewardRate = 10;
    const minStake = 100;
    const description = "Offer - 1";

    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description);
    await createOfferTx.wait();

    await token.approve(staking.target, "500");

    const stakeTx1 = await staking.stake(0, 100, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx1.wait();

    const stakeTx2 = await staking.stake(0, 200, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx2.wait();

    const stakeTx3 = await staking.stake(0, 200, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx3.wait();

    const [,,,,numberOfStakers,,,] = await staking.stakingOffers(0);
    expect(numberOfStakers).to.equal(3);
  });


   it("should withdraw rewards correctly", async function () {
    const duration = 3600; // 1 hour
    const rewardRate = 10; // 10%
    const minStake = 100;
    const description = "Offer - 1";

    // Create offer
    const createOfferTx = await staking.createOffer(minStake, rewardRate, duration, description);
    await createOfferTx.wait();

    // Approve and stake tokens
    await token.approve(staking.target, "200");
    const stakeTx = await staking.stake(0, 100, [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);
    await stakeTx.wait();

    

    // Withdraw rewards
    const withdrawTx = await staking.withdrawReward(0);
    const withdrawTxReceipt = await withdrawTx.wait();

    console.log("Withdraw tx receipt:", withdrawTxReceipt);

  });

});
