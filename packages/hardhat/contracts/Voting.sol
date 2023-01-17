pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/**
  @notice Gas efficient on-chain voting using packed proposals
  @author lourens.eth

      NB  This contract is for educational purposes only and should not 
          be used in a production environment without modification.

    @dev  The contract is an experiment in using bit packing to store
          different variables inside one uint256 value.

          The `_packedProposalRecords` mapping contains uint256 values
          which in packed form contain the `vote start time`,
          the `vote end time`, the `votes for` and the `votes against`,
          as well as `extra data`

  A note on formatting: the `Proposal` struct, errors and events are
  implemented in the `IVoting.sol` interface.

  Some assumptions:
  - voting power assumes a total maximum of `type(uint80).max -1` in cumulative votes
  - for this concept when calling `vote` a user spends and loses all voting power
  - if linked to a voting token, this could be set using `_beforeTokenTransfer` hook 
    or equivalent in the associated token contract
 */

/****************************************************************************
 *                               IMPORTS                                    *
 ****************************************************************************/
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

  /**
    @notice Packs `data` into bit positions [240-255] in the `result`
    @dev    Note that this deletes the current `extraData`
    @param  proposalId The ID of the proposal record being packed
    @param  extraData The data being packed into the record (in uint16 format)
    @return result The proposal record packed into uint256 format
   */
  function _packExtraData(uint32 proposalId, uint16 extraData) internal view returns (uint256 result) {
    result = _packedProposalRecords[proposalId];

    assembly {
      result := or(result, extraData)
    }
  }

  /**
    @notice Packs the supplied vote times into the proposal record
    @param  proposalId The ID of the target proposal record
    @param  voteStart The vote start date
    @param  voteEnd The vote end date
    @return result The proposal record packed into uint256 format
   */
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

  /**
    @notice Calculates and packs votes
    @param  proposalId The ID of the target proposal record
    @param  votes The amount of votes to add to the target proposal record
    @param  choice Voting for or against the target proposal
   */
  function _packVotes(
    uint32 proposalId,
    uint80 votes,
    bool choice
  ) internal view returns (uint256 result) {
    result = _packedProposalRecords[proposalId];
    /// Isolate and increment the number of votes
    uint80 currentVotes = uint80(result >> (choice ? _BIT_OFFSET_VOTES_FOR : _BIT_OFFSET_VOTES_AGAINST));
    
    unchecked {
      votes += currentVotes;
    }

    assembly {
      if eq(choice, true) {
        result := or(and(result, _BITMASK_VOTES_FOR_COMPLEMENT), shl(_BIT_OFFSET_VOTES_FOR, votes))
      }
      
      if eq(choice, false) {
        result := or(and(result, _BITMASK_VOTES_AGAINST_COMPLEMENT), shl(_BIT_OFFSET_VOTES_AGAINST, votes))
      }
    }
  }

  /**
    @notice Unpacks the given uint256 into a `Proposal` struct
    @param  packedRecord The packed record in uint256 format
    @return unpackedProposal The `Proposal` struct constructed from the `packedRecord` 
   */
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

  /// @inheritdoc IVoting
  function propose(
    bytes32 proposalHash,
    uint256 voteStart,
    uint256 voteEnd
  ) public returns (uint32 proposalId) {
    proposalId = proposalCounter;

    unchecked {
      proposalCounter++;
    }

    _proposals[proposalId] = proposalHash;
    _packedProposalRecords[proposalId] = _packVoteTimes(proposalId, voteStart, voteEnd);
  }

  /****************************************************************************
   *                            VOTE OPERATIONS                               *
   ****************************************************************************/

  /// @inheritdoc IVoting
  function setVotingPower(address voter, uint80 votingPower) external {
    _votingPower[voter] = votingPower;
  }

  /// @inheritdoc IVoting
  function vote(uint32 proposalId, bool choice) external {
    if (block.timestamp < viewVoteStart(proposalId)) {revert Early();}
    if (block.timestamp > viewVoteEnd(proposalId)) {revert Late();}

    _packedProposalRecords[proposalId] = _packVotes(proposalId, _votingPower[msg.sender], choice);

    delete _votingPower[msg.sender];

    emit Voted(proposalId, _votingPower[msg.sender], choice, msg.sender);
  }

  /****************************************************************************
   *                            VIEWING OPERATIONS                            *
   ****************************************************************************/

  /**
    @dev  Returns the proposal record in packed uint256 format
   */
  function viewPackedProposalRecord(uint32 proposalId) external view returns (uint256) {
    return _packedProposalRecords[proposalId];
  }

  /**
    @dev  Returns the vote start time in uint40 unix
   */
  function viewVoteStart(uint32 proposalId) public view returns (uint40) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.voteStart;
  }

  /**
    @dev  Returns the vote end time in uint40 unix
   */
  function viewVoteEnd(uint32 proposalId) public view returns (uint40) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.voteEnd;
  }

  /**
    @dev  Returns the amount of votes for the target `proposalId`
   */
  function viewVotesFor(uint32 proposalId) external view returns (uint80) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.votesFor;
  }

  /**
    @dev  Returns the amount of votes against the target `proposalId`
   */
  function viewVotesAgainst(uint32 proposalId) external view returns (uint80) {
    Proposal memory _unpacked = _unpackProposalRecord(_packedProposalRecords[proposalId]);
    return _unpacked.votesAgainst;
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
