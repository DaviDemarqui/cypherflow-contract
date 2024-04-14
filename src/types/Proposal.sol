// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 amount;
    address payable recipient;
    uint256 startTime;
    uint256 endTime;
    uint256 yesVote;
    uint256 noVotes;
    EnumerableSet.AddressSet voters;
    bool executed;
}

