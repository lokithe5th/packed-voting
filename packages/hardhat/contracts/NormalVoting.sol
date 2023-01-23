pragma solidity 0.8.17;

import "./interfaces/IVoting.sol";

contract NormalVoting is IVoting {

    mapping(uint32 => Proposal) private _proposalStructs;
    mapping(uint32 => bytes32) private _proposals;
    mapping(address => uint80) private _votingPower;

    uint32 private proposalCounter;

    function propose(
        bytes32 proposalHash,
        uint40 voteStart,
        uint40 voteEnd
    ) external returns (uint32 proposalId) {
        proposalId = proposalCounter;

        Proposal storage proposal = _proposalStructs[proposalId];
        proposal.voteStart = voteStart;
        proposal.voteEnd = voteEnd;

        _proposals[proposalId] = proposalHash;

        unchecked {
            proposalCounter++;
        }
    }

    function setVotingPower(address voter, uint80 votingPower) external {
        _votingPower[voter] = votingPower;
    }

    function vote(uint32 proposalId, bool choice) external {
        if (block.timestamp < _proposalStructs[proposalId].voteStart) {revert Early();}
        if (block.timestamp > _proposalStructs[proposalId].voteEnd) {revert Late();}

        Proposal storage proposal = _proposalStructs[proposalId];
        if (choice) {
            proposal.votesFor += _votingPower[msg.sender];
        } else {
            proposal.votesAgainst += _votingPower[msg.sender];
        }

        emit Voted(proposalId, _votingPower[msg.sender], choice, msg.sender);

        delete _votingPower[msg.sender];
    }

    function viewVoteStart(uint32 proposalId) external view returns (uint40) {
        return _proposalStructs[proposalId].voteStart;
    }

    function viewVoteEnd(uint32 proposalId) external view returns (uint40) {
        return _proposalStructs[proposalId].voteEnd;
    }

    function viewVotesFor(uint32 proposalId) external view returns (uint80) {
        return _proposalStructs[proposalId].votesFor;
    }

    function viewVotesAgainst(uint32 proposalId) external view returns (uint80) {
        return _proposalStructs[proposalId].votesAgainst;
    }

    function viewProposalRecord(uint32 proposalId) external pure returns (uint256) {
        return proposalId;
    }
}