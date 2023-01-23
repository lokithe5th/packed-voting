//  Init the test environment
const { ethers } = require('hardhat');

const initialize = async (accounts) => {
  const setup = {};
  setup.roles = {
    root: accounts[0],
    user1: accounts[1],
    user2: accounts[2]
  };

  return setup;
};

const voting = async (setup) => {
    const votingContractFactory = await ethers.getContractFactory("PackedVoting");
    let votingContract = await votingContractFactory.deploy();

    return votingContract;
}

module.exports = {
  initialize,
  voting
}; 
