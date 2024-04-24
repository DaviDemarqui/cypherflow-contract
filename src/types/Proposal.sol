// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

// @author: Dave
// @notice: The proposalType is used to inform what kind of action
// this proposal will do and also is used to inform the completion
// function what to do next
enum ProposalType {
    AutoVoteForWinnerAnswer,
    DeleteMember,
    DeleteQuestion,
    UpdateRewardRate,
    UpdateMinGovEntranceThreshold, // Update the MIN_GOV_ENTRANCE_THRESHOLD
    UpdateMinPropThreshold, // Update the MIN_PROPOSAL_THRESHOLD
    UpdateMinVotThreshold // Update the MIN_VOTING_THRESHOLD
}

// @notice: "updateValue" is used when the proposal is going
// to update a value, "deleteValue" is used  deleting.
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

