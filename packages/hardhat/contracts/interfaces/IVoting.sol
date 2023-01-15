pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT


interface IVoting {
  /****************************************************************************
   *                                 ERRORS                                   *
   ****************************************************************************/


  /****************************************************************************
   *                                 EVENTS                                   *
   ****************************************************************************/

  event Voted(
    uint256 indexed proposalId,
    uint256 indexed amountVotes,
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

  function propose(
    bytes32 proposal,
    uint256 voteStart,
    uint256 voteEnd
  ) external returns (uint32 proposalId);

  /****************************************************************************
   *                            VOTE FUNCTIONS                                *
   ****************************************************************************/

  function vote(uint32 proposalId, bool choice, address voter) external;

  /****************************************************************************
   *                          VIEWER FUNCTIONS                                *
   ****************************************************************************/

  function viewPackedProposalRecord(uint32 proposalId) external view returns (uint256);

  function viewVoteStart(uint32 proposalId) external view returns (uint40);

  function viewVoteEnd(uint32 proposalId) external view returns (uint40);

}
