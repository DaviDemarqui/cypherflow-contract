//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct User {
    string username;
    address userAddress;
    uint256 amountStaked;
    int256 reputation;
    uint256 rewards;
    bool govMember;
}