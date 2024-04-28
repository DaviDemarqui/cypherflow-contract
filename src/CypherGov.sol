//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CypherCore.sol";
import "./types/User.sol";
import "./types/Proposal.sol";
import "./token/CypherToken.sol";
import "./library/IdGenerator.sol";

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/access/Ownable.sol";

// @author: Dave
// @notice: CypherGov is a contract tha is used to
// manage the CypherFlow DAO. Here the proposals are
// voted and created.
contract CypherGov is Ownable {

    // ========================
    // *       STORAGE        *  
    // ========================

    using EnumerableSet for EnumerableSet.addressSet;

    uint public govBalance;

    CypherToken public cypherToken;
    CypherCore public CypherCore;

    // The minimum amount of tokens required to become a gov member
    uint256 public constant MIN_GOV_ENTRANCE_THRESHOLD = 1000 * 10**18;

    // The minimum amount of tokens required to create a proposal
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 100 * 10**18;

    // The minimum amount of tokens required to vote on a proposal
    uint256 public constant MIN_VOTING_THRESHOLD = 10 * 10**18;

    mapping(bytes32 => Proposal) public proposals;
    mapping(address => bool) public activeProposals;

    // ========================
    // *    EVENTS & ERRORS   *  
    // ========================
    event NewGovMember(address indexed _newMemberAddress);
    event NewProposal(uint256 indexed _proposalId, address indexed _proposer, ProposalType indexed _proposalType); 
    event ProposalExecuted(uint256 indexed _proposalId, address indexed _proposer, ProposalType indexed _proposalType);

    error InvalidGovAmmount(uint256 _ammount, address _sender);
    
    // ========================
    // *      MODIFIERS       *  
    // ========================

    modifier onlyCreator {
        require(msg.sender == cypherCore.creator, "The sender is not the creator");
        _;
    }

    modifier onlyUsers {
        require(msg.sender == cypherCore.users(msg.sender).userAddress, "The sender is not a user of the platform");
        _;
    }

    modifier onlyGovMembers {
        require(cypherCore.users(msg.sender).govMember == true, "The sender is not a governance member");
        _;
    }

    // ===========================
    // * CONSTRUCTOR & FUNCTIONS *  
    // ===========================

    constructor(CypherCore _cypherCore, CypherToken _cypherToken) {
        cypherToken = _cypherToken;
        cypherCore = _cypherCore;
    }

    function becomeGovMember() onlyUsers payable public {
        if (msg.value >= MIN_GOV_ENTRANCE_THRESHOLD) { 
            cypherGov.updateUserGov(msg.sender, msg.value);
            govBalance += msg.value;
        } else {
            revert InvalidGovAmmount(msg.value, msg.sender);
        }
        emit NewGovMember(msg.sender);
    }

    // Function to create a new Proposal
    function createProposal(string memory _description, uint256 _value, ProposalType _proposalType) onlyGovMembers public {
        require(cypherToken.balanceOf(msg.sender) >= MIN_PROPOSAL_THRESHOLD, "Insufficient tokens to create proposal");
        require(!activeProposals[msg.sender], "You already have an active proposal");

        Proposal memory newProposal = Proposal({
            id: IdGenerator.generateId(msg.sender),
            proposer: msg.sender,
            description: _description,
            value: _value,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days,
            yesVote: 0,
            noVotes: 0,
            voters: new EnumerableSet.AddressSet(),
            proposalType: _proposalType,
            executed: false
        });

        activeProposals[msg.sender] = true;
        proposals[newProposal.id] = newProposal;
        emit NewProposal(newProposal.id, msg.sender, newProposal.proposalType);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _support) onlyGovMembers public {
        User memory votingUser = cypherCore.users(msg.sender);
        Proposal storage proposal = proposals[_proposalId];

        require(votingUser.amountStaked >= MIN_VOTING_THRESHOLD, "Insufficient tokens to vote");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Invalid voting period");
        require(!proposal.voters.contains(msg.sender), "You already voted on this proposal");
        
        if(_support) { proposal.yesVote += votingUser.amountStaked;} 
        else { proposal.noVotes += votingUser.amountStaked;}

        proposal.voters.add(msg.sender);
    }

    function executeProposal(bytes32 _proposalId) onlyGovMembers public {
        Proposal memory selectedProposal = proposal[_proposalId];

        require(!selectedProposal.executed, "Proposal has already been executed");
        require(block.timestamp > selectedProposal.endTime, "Voting period is still ongoing");
        require(selectedProposal.yesVote > selectedProposal.noVotes, "Proposal has no reached majority support");

        // Checking proposalType for execution
        if(selectedProposal.proposalType == ProposalType.DeleteQuestion) {
            cypherCore.deleteQuestion(bytes32(selectedProposal.value));
        } else if(selectedProposal.proposalType == ProposalType.UpdateRewardRate) {
            cypherCore.updateRewardRate(selectedProposal.value);
        } else if(selectedProposal.proposalType == ProposalType.UpdateMinPropThreshold) {
            MIN_PROPOSAL_THRESHOLD = selectedProposal.value;
        } else if (selectedProposal.proposalType == ProposalType.UpdateMinVotThreshold) {
            MIN_VOTING_THRESHOLD = selectedProposal.value;
        } else if (selectedProposal.proposalType == ProposalType.RemoveMember) {
            cypherCore.deleteUser(selectedProposal.value);
        }

        emit ProposalExecuted(selectedProposal.id, selectedProposal.proposer, selectedProposal.proposalType);
    }

    // Funcion to withdraw funds from the DAO
    function withdraw(uint256 _amount) external onlyCreator {
        payable(owner()).transfer(_amount);
    }

    receive() external payable {}
}