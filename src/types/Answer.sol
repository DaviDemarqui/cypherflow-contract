//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct Answer {
    bytes32 id;
    string answer;
    address creator;
    uint256 createdAt;
    int256 vote;
}