// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

// @author: Dave
// @notice: The proposalType is used to inform what kind of action
// this proposal will do and also is used to inform the completion
// function what to do next
enum ProposaType {
    VoteAnswerWinner,
    DeleteQuestion,
    DeleteAnswer,
    UpdateReward,
    UpdateFeeRate
}

// @notice: "value" is used for updates and also 
// to pass a information to a function
struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 value; 
    uint256 startTime;
    uint256 endTime;
    uint256 yesVote;
    uint256 noVotes;
    EnumerableSet.AddressSet voters;
    ProposalType proposalType;
    bool executed;
}

