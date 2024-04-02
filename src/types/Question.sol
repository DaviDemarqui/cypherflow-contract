//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct Question {
    bytes32 id;
    string question;
    address creator;
    uint256 createdOn;
    bool resolved;
} 
