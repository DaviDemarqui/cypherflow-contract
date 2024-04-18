//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CypherCore.sol";
import "./types/User.sol";
import "./types/Proposal.sol";
import "./token/CypherToken.sol";

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/access/Ownable.sol";

// @author: Dave
// @notice: CypherGov is a contract tha is used to
// manage the CypherFlow DAO. Here the proposals are
// voted and created.
contract CypherGov is Ownable {

    using EnumerableSet for EnumerableSet.addressSet;

    // The DAO Token contract
    CypherToken public cypherToken;

    CypherCore CypherCore;

    // The minimum amount of tokens required to create a proposal
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 1000 * 10**18;

    // The minimum amount of tokens required to vote on a proposal
    uint256 public constant MIN_VOTING_THRESHOLD = 100 * 10**18;

    // Array of all proposals
    Proposal[] public proposals;

    // Mapping to check if an address has an active proposal
    mapping(address => bool) public activeProposals;

    // Event for a new proposal
    event NewProposal(uint256 indexed _proposalId, address indexed _proposer, address indexed _recipient, uint256 _amount); 

    constructor(CypherCore _cypherCore, CypherToken _cypherToken) {
        cypherToken = _cypherToken;
        cypherCore = _cypherCore;
    }

    // Function to create a new Proposal
    function createProposal(string memory _description, uint256 _amount, address payable _recipient) external {
        require(cypherToken.balanceOf(msg.sender) >= MIN_PROPOSAL_THRESHOLD, "Insufficient tokens to create proposal");
        require(!activeProposals[msg.sender], "You already have an active proposal");

        Proposal memory newProposal = Proposal({
            id: proposals.length,
            proposer: msg.sender,
            description: _description,
            amount: _amount,
            recipient: _recipient,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days,
            yesVote: 0,
            noVotes: 0,
            voters: new EnumerableSet.AddressSet(),
            executed: false
        });

        proposals.push(newProposal);
        activeProposals[msg.sender] = true;
        emit NewProposal(newProposal.id, msg.sender, _description, _amount);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _support) external {
        require(cypherToken.balanceOf(msg.sender) >= MIN_VOTING_THRESOLD, "Insufficient tokens to vote");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Invalid voting period");
        require(!proposal.voters.contains(msg.sender), "You already voted on this proposal");

        uint256 voterWeight = cypherToken.balanceOf(msg.sender);
        if(_support) {
            proposal.yesVote += voterWeight;
        } else {
            proposal.noVotes += voterWeight;
        }

        proposal.voters.add(msg.sender);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposal[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp > proposal.endTime, "Voting period is still ongoing");
        require(proposal.yesVote > proposal.noVotes, "proposal has not reached majority support");

        proposal.recipient.transfer(proposal.amount);
        proposal.executed = true;
        activeProposals[proposal.proposer] = false;
        emit ProposalExecuted(_proposalId, proposal.proposer, proposal.recipient, proposal.amount);
    }

    // Funcion to withdraw funds from the DAO
    function withdraw(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    receive() external payable {}
}