const { expect } = require("chai");

describe("Staking", function () {
  it("should depoy", async () => {
    // deployer addres
    const [owner] = await ethers.getSigners();
    console.log("Deploying contract with the account:", owner.address);

    const Token = await ethers.getContractFactory("Token");
    const Staking = await ethers.getContractFactory("Stakings");

    const token = await Token.deploy();
    console.log("Token deployed to:", token.target);
    const staking = await Staking.deploy(token.target);
    console.log("Staking deployed to:", staking.target);

    expect(await token.balanceOf(owner.address)).to.equal("100000000000000000000000"); // checking balance of owner

    //stake 100 tokens
    const approveTx = await token.approve(staking.target, "100");
    const tx = await approveTx.wait();

    // check allowance
    expect(await token.allowance(owner.address, staking.target)).to.equal("100");

    const stakeTx = await staking.stake("100", [
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
      '0x59f6E436AD3a61Ba435e8a6F310c8A6128AF84f2',
    ]);

    const stakeTxReceipt = await stakeTx.wait();

    expect(await staking.totalStaked()).to.equal("100");
  });
});
