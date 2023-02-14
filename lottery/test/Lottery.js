const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Lottery contract", function () {
  it("Deployment should assign the manager of the lottery as msg.sender", async function () {
    const [owner] = await ethers.getSigners();
    const ownerAddress = owner.address;

    const Lottery = await ethers.getContractFactory("Lottery");
    const hardhatLottery = await Lottery.deploy();

    const manager = await hardhatLottery.manager();
    expect(manager).to.equal(ownerAddress);
  });

  it("Should deploy the contract and allow the owner to check the balance", async function () {
    // const[owner, player1, player2, player3] = await ethers.getSigners();

    // const Lottery = await ethers.getContractFactory("Lottery");
    // const hardhatLottery = await Lottery.deploy();

    // const ownerBalance = await owner.getBalance()

    // console.log(ownerBalance)

    // const balance = await hardhatLottery.getBalance();
    // expect(balance).to.equal(0);

  });
});