pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT


interface IVoting {
  /****************************************************************************
   *                                 ERRORS                                   *
   ****************************************************************************/
  /// Voting hasn't started yet
  error Early();
  /// Voting is over
  error Late();

  /****************************************************************************
   *                                 EVENTS                                   *
   ****************************************************************************/

  event Voted(
    uint32 indexed proposalId,
    uint80 indexed amountVotes,
    bool indexed voted,
    address voter
  );

  /****************************************************************************
   *                                STRUCTS                                   *
   ****************************************************************************/

  struct Proposal {
    uint40 voteStart;
    uint40 voteEnd;
    uint80 votesFor;
    uint80 votesAgainst;
    uint16 extraData;
  }

  /****************************************************************************
   *                           PROPOSE FUNCTIONS                              *
   ****************************************************************************/

  /**
    @notice Allows a user to make a proposal
    @param  proposalHash The hash of the proposal
    @param  voteStart The unix timestamp representing the voting start time
    @param  voteEnd The unix timestamp representing the voting end time
    @return proposalId The ID of the proposal
   */
  function propose(
    bytes32 proposalHash,
    uint256 voteStart,
    uint256 voteEnd
  ) external returns (uint32 proposalId);

  /****************************************************************************
   *                            VOTE FUNCTIONS                                *
   ****************************************************************************/

  /**
  @notice Sets the voting power for the target address
  @param  voter The target address
  @param  votingPower The voting power accrued to the target address
   */
  function setVotingPower(address voter, uint80 votingPower) external;

  /**
    @notice Allows a user to vote on an open proposal
    @param  proposalId The ID of the target proposal
    @param  choice Bool representing support or opposition for proposal
    @
   */
  function vote(uint32 proposalId, bool choice) external;

  /****************************************************************************
   *                          VIEWER FUNCTIONS                                *
   ****************************************************************************/

  function viewProposalRecord(uint32 proposalId) external view returns (uint256);

  function viewVoteStart(uint32 proposalId) external view returns (uint40);

  function viewVoteEnd(uint32 proposalId) external view returns (uint40);

}
