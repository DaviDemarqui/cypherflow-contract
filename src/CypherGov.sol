//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CypherCore.sol";
import "./types/User.sol";

// @author: Dave
// @notice: CypherGov is a contract tha is used to
// manage the CypherFlow DAO. Here the proposals are
// voted and created.
contract CypherGov {

    // ========================
    // *       STORAGE        *  
    // ========================
    CypherCore cypherCore;

    mapping(address => User) private members;

    constructor(CypherCore _cypherCore) {
        cypherCore = _cypherCore;
    }
}