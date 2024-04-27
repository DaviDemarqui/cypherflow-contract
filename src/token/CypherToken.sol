//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract CypherToken is ERC20 {

    address creator;
    uint256 totalSupply;

    constructor(uint256 _initialSupply) ERC20("CYPHER Token", "CYP") {
        _mint(msg.sender, _initialSupply);
        totalSupply = _initialSupply;
        creator = msg.sender;
    }


}