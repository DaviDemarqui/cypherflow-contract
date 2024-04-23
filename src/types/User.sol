//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct User {
    string username;
    address userAddress;
    uint256 cypEarned;
    int256 reputation;
    bool govMember;
}