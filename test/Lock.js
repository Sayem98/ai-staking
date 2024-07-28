const { expect } = require("chai");

describe("Staking", function () {
  it("should depoy", async () => {
    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy();
    expect(await staking.totalStaked()).to.equal("0");
  });
});
