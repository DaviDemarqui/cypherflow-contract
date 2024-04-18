// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

enum ProposaType {
    VoteAnswerWinner,
    DeleteQuestion,
    DeleteAnswer,
    UpdateReward,
    UpdateFeeRate
}

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 newValue; // Used when updating a value
    uint256 startTime;
    uint256 endTime;
    uint256 yesVote;
    uint256 noVotes;
    EnumerableSet.AddressSet voters;
    ProposalType proposalType;
    bool executed;
}

