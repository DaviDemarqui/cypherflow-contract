//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct Answer {
    bytes32 id;
    string answer;
    address creator;
    bytes32 answeredTo;
    int256 vote;
    bool won;
}