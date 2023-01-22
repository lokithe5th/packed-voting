pragma solidity 0.8.17;

contract NormalVoting {

    struct Proposal {
        uint40 voteStart;
        uint40 voteEnd;
        uint80 votesFor;
        uint80 votesAgainst;
        uint16 extraData;
    }

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

        proposalCounter++;
    }

    function setVotingPower(address voter, uint80 votingPower) external {
        _votingPower[voter] = votingPower;
    }

    function vote(uint32 proposalId, bool choice) external {

    }

    function viewProposalRecord(uint32 proposalId) external view returns (Proposal memory proposal) {
        return _proposalStructs[proposalId];
    }

    function viewVoteStart(uint32 proposalId) external view {

    }

    function viewVoteEnd(uint32 proposalId) external view {

    }

    function viewVotesFor(uint32 proposalId) external view {

    }

    function viewVotesAgainst(uint32 proposalId) external view {

    }
}