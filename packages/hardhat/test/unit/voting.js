const { ethers, utils } = require("hardhat");
const { expect } = require("chai");
const init = require('../test-init.js');

let votingContract;
let voteStart = 1673849488;
let voteEnd = 2673849488;

describe("Packed Voting", function () {

  const setupTests = deployments.createFixture(async () => {
    const signers = await ethers.getSigners();
    const setup = await init.initialize(signers);

    root = setup.roles.root;
    user1 = setup.roles.user1;
    user2 = setup.roles.user2;

    votingContract = await init.voting();

  });

  before("Setup", async () => {
    await setupTests();
  });

  describe("Voting Contract", function () {
    describe("propose()", function () {
      it("Should be able to make a new proposal", async function () {
        const newProposal = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"));

        await votingContract.propose(newProposal, voteStart, voteEnd);
      });
    });

    describe("viewPackedProposalRecord()", function () {
      it("Should return the proposal in packed uint256 format", async function () {
        expect(await votingContract.viewPackedProposalRecord(0)).to.not.be.null;
      })
    });

    describe("viewVoteStart()", function () {
      it("Should return the proposal start time in unix format", async function () {
        expect(await votingContract.viewVoteStart(0)).to.equal(voteStart);
      })
    });

    describe("viewVoteEnd()", function () {
      it("Should return the proposal end end in unix format", async function () {
        expect(await votingContract.viewVoteEnd(0)).to.equal(voteEnd);
      })
    });

    describe("setVotingPower()", function () {
      it("Should set the target voting power", async function () {
        await votingContract.setVotingPower(user1.address, 100);
        await votingContract.setVotingPower(user2.address, 100);
        await votingContract.setVotingPower(root.address, 200);
      });
    });

    describe("vote()", function () {
      it("Should allow a user to vote and emit the appropriate event", async function () {
        await expect(votingContract.connect(user1).vote(0, true)).to.emit(votingContract, "Voted");
        await expect(votingContract.connect(user2).vote(0, false)).to.emit(votingContract, "Voted");
      });
    });

    describe("viewVotesFor()", function () {
      it("Should return the appropriate vote count", async function () {
        expect(await votingContract.viewVotesFor(0)).to.equal(100);
        expect(await votingContract.viewVotesAgainst(0)).to.equal(100);
      });
    });

    describe("vote()", function () {
      it("Should be able to change the votes for without losing previous values", async function () {
        await votingContract.vote(0, true);
        expect(await votingContract.viewVotesFor(0)).to.equal(300);
      });
    });
  });
});
