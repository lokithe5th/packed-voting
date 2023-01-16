const { ethers, utils } = require("hardhat");
const { expect } = require("chai");

describe("Packed Voting", function () {
  let votingContract;
  let voteStart = 1673849488;
  let voteEnd = 2673849488;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("Voting", function () {
    it("Should deploy Voting", async function () {
      const Voting = await ethers.getContractFactory("Voting");

      votingContract = await Voting.deploy();
    });

    describe("propose()", function () {
      it("Should be able to make a new proposal", async function () {
        const newProposal = utils.keccak256(utils.toUtf8Bytes("test"));

        await votingContract.propose(newProposal, voteStart, voteEnd);
      });

      it("Should emit a SetPurpose event ", async function () {
        const [owner] = await ethers.getSigners();

        const newPurpose = "Another Test Purpose";

        expect(await myContract.setPurpose(newPurpose))
          .to.emit(myContract, "SetPurpose")
          .withArgs(owner.address, newPurpose);
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
      it("Should return the proposal start end in unix format", async function () {
        expect(await votingContract.viewVoteStart(0)).to.equal(voteEnd);
      })
    });

    describe("setVotingPower()", function () {
      it("Should return the proposal start time in unix format", async function () {
        expect(await votingContract.setVotingPower()).to.equal(voteStart);
      })
    });
  });
});
