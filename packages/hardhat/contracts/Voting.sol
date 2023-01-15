pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/**
  @notice Gas efficient on-chain voting using packed proposals
  @author lourens.eth

  @dev  This contract is an experiment in using bit packing to store
        different variables inside one uint256 value.

        In this contract this is focused on `_packedProposalRecords`
        The mapping contains uint256 values which in packed form contain 
        the `vote start time`, the `vote end time`, the `votes for` and
        the `votes against`, as well as `extra data`

 */

import "./interfaces/IVoting.sol";

contract Voting is IVoting {
  /****************************************************************************
   *                              CONSTANTS                                   *
   ****************************************************************************/

  /**
    The mask to zero out the values of `voteFor` in `_packedProposals`
   */
  uint256 private constant _BITMASK_VOTES_FOR_COMPLEMENT =
    0xFFFFFFFFFFFFFFFFFFFF00000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

  /**
    The mask to zero out the values of `voteAgainst` in `_packedProposals`
   */
  uint256 private constant _BITMASK_VOTES_AGAINST_COMPLEMENT =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000FFFF;

  /**
    Note: Bit offsets below refer to the number of bits the packed proposal
          needs to be shifted to the right to bring the target bit range
          into position.
   */

  /**
    The start bit position for `voteStart` in `_packedProposals`
   */
  uint256 private constant _BIT_OFFSET_VOTE_START = 216;

  /**
    The start bit position for `voteEnd` in `_packedProposals`
   */
  uint256 private constant _BIT_OFFSET_VOTE_END = 176;

  /**
    The start bit position for `votesFor` in `_packedProposals`
   */
  uint256 private constant _BIT_OFFSET_VOTES_FOR = 96;

  /**
    The start bit position for `votesAgainst` in `_packedProposals`
   */
  uint256 private constant _BIT_OFFSET_VOTES_AGAINST = 16;

  /**
    Note that there is no bit offset value for `extraData`
    The `extraData` bits start at bit position 255
   */

  /****************************************************************************
   *                                STORAGE                                   *
   ****************************************************************************/
  /**
    Keeps track of the proposals
   */
  uint32 private proposalCounter;

  /**
    The mapping of proposal Id proposal records containing:
    - vote starting time [40 bits]
    - vote end time [40 bits]
    - the number of votes for [80 bits]
    - the number of votes against [80 bits]
    - extra data [16 bits]

    Bits Layout:
   - [0-39]     `voteStart`
   - [40-79]    `voteEnd`
   - [80-159]   `votesFor`
   - [160-239]  `votesAgainst`
   - [240-256]  `extraData`
   */
  mapping(uint32 => uint256) private _packedProposalRecords;

  /**
    Mapping of proposal Id to hash of the proposal contents
   */
  mapping(uint32 => bytes32) private _proposals;

  /**
    The contract is intended to be voting power agnostic
    and expects voting power to be set through another mechanism
   */
  mapping(address => uint80) private _votingPower;

  /****************************************************************************
   *                   INTERNAL PACKING OPERATIONS                            *
   ****************************************************************************/

  function _packExtraData(uint32 proposalId, uint16 extraData) internal view returns (uint256 result) {
    result = _packedProposalRecords[proposalId];

    assembly {
      result := or(result, extraData)
    }
  }

  function _packVoteTimes(
    uint32 proposalId,
    uint256 voteStart, 
    uint256 voteEnd
  ) internal view returns (uint256 result) {
    result = _packedProposalRecords[proposalId];

    assembly {
      result := or(result, or(shl(_BIT_OFFSET_VOTE_START, voteStart), shl(_BIT_OFFSET_VOTE_END, voteEnd)))
    }
  }

  function _packVotes(uint32 proposalId, uint80 votes, bool choice) internal view returns (uint256 result) {
    result = _packedProposalRecords[proposalId];
    /// Isolate and increment the number of votes
    uint80 currentVotes = uint80(result >> (choice ? _BIT_OFFSET_VOTES_FOR : _BIT_OFFSET_VOTES_AGAINST));
    votes += currentVotes;

    assembly {
      if eq(choice, true) {
        result := and(result, _BITMASK_VOTES_FOR_COMPLEMENT)
        result := or(result, shl(_BIT_OFFSET_VOTES_FOR, votes))
      }
      
      if eq(choice, false) {
        result := and(result, _BITMASK_VOTES_AGAINST_COMPLEMENT)
        result := or(result, shl(_BIT_OFFSET_VOTES_AGAINST, votes))
      }
    }
  }

  function _unpackProposalRecord(uint256 packedRecord) internal pure returns (Proposal memory unpackedProposal) {
    unpackedProposal.voteStart = uint40(packedRecord >> _BIT_OFFSET_VOTE_START);
    unpackedProposal.voteEnd = uint40(packedRecord >> _BIT_OFFSET_VOTE_END);
    unpackedProposal.votesFor = uint80(packedRecord >> _BIT_OFFSET_VOTES_FOR);
    unpackedProposal.votesAgainst = uint80(packedRecord >> _BIT_OFFSET_VOTES_AGAINST);
    unpackedProposal.extraData = uint16(packedRecord);
  }

  /****************************************************************************
   *                            PROPOSE OPERATIONS                            *
   ****************************************************************************/

  function propose(
    bytes32 proposalHash,
    uint256 voteStart,
    uint256 voteEnd
  ) public returns (uint32 proposalId) {
    proposalId = proposalCounter;
    proposalCounter++;

    _proposals[proposalId] = proposalHash;

    _packedProposalRecords[proposalId] = _packVoteTimes(proposalId, voteStart, voteEnd);
  }

  /****************************************************************************
   *                            VOTE OPERATIONS                               *
   ****************************************************************************/

  function vote(uint32 proposalId, bool choice, address voter) external {
    _packedProposalRecords[proposalId] = _packVotes(proposalId, _votingPower[voter], choice);
    delete _votingPower[voter];
  }

  /****************************************************************************
   *                            VIEWING OPERATIONS                            *
   ****************************************************************************/

  function viewPackedProposalRecord(uint32 proposalId) external view returns (uint256) {
    return _packedProposalRecords[proposalId];
  }

  function viewVoteStart(uint32 proposalId) external view returns (uint40) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.voteStart;
  }

  function viewVoteEnd(uint32 proposalId) external view returns (uint40) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.voteEnd;
  }

  function viewVotesFor(uint32 proposalId) external view returns (uint80) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.votesFor;
  }

  function viewVotesAgainst(uint32 proposalId) external view returns (uint80) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.votesAgainst;
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
