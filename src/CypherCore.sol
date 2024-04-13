//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CypherGov.sol";
import "./types/Question.sol";
import "./types/Answer.sol";
import "./types/User.sol";
import "./library/IdGenerator.sol";

// @author: Dave
// @notice: CypherCore is the contract that manages almost all the 
// functionalities of the platform except for the governance.
contract CypherCore {

    // ========================
    // *    EVENTS & ERRORS   *  
    // ========================
    event questionCreated(address _creator, bytes32 _questionId);
    event questionAnswered(address _user, bytes32 _questionId);
    event questionDeleted(bytes32 _questionId);

    event answerVoted(bytes32 _currentVote, address _voter);
    event answerDeleted(bytes32 _answerId);

    event feeRateUpdated(uint256 _newFee);
    event rewardUpdated(uint256 _newReward);

    error invalidFeeRate(uint256 _feeRate);
    error invalidReward(uint256 _newReward);
    error invalidUser(address _user);
    error invalidAnswerData(bytes32 _questionId);
    error invalidAnswerVote();
    error invalidQuestion(bytes32 _question);
    error questionAlreadyResolved(bytes32 _questionId);

    // ========================
    // *        ENUM          *  
    // ========================
    enum VoteType {
        UPVOTE,
        DOWNVOTE
    }

    // ========================
    // *       STORAGE        *  
    // ========================
    address creator;
    uint256 feeRate;
    uint256 reward;
    uint256 maxReward;
    
    mapping(address => User) public users;
    mapping(bytes32 => Answer) public answers;
    mapping(bytes32 => Question) public questions;

    constructor(uint256 _feeRate, uint256 _reward, uint256 _maxReward) {
        creator = msg.sender;
        feeRate = _feeRate;
        reward = _reward;
        maxReward = _maxReward;
        // cypherGov = new CypherGov((this));
    }

    function createQuestion(Question memory _question) public {
        if (msg.sender != _question.creator) {
            revert invalidUser(msg.sender);
        }

        // Generating the quesion id using the generateId
        // function from the IdGenerator.sol
        _question.id = IdGenerator.generateId(msg.sender);
        questions[_question.id] = _question;
        emit questionCreated(msg.sender, _question.id);
    }

    function deleteQuestion(bytes32 _questionId) public {

        // todo - validate so the governance can also delete
        // questions;
        if(questions[_questionId].creator != msg.sender) {
            revert invalidUser(msg.sender);
        }

        delete questions[_questionId];
        emit questionDeleted(_questionId);
    }

    // todo - fix the problem to validate the user payment accordingly with
    // the answer conclusion.
    function answerQuestion(Answer memory _answer, bytes32 _questionId) public {
        
        if (questions[_questionId].resolved == true) { 
            revert questionAlreadyResolved(_questionId); 
        } 
        else if (questions[_questionId].creator == _answer.creator || msg.sender != _answer.creator) {
            revert invalidUser(msg.sender);
        }
        else if (_answer.vote != 0 || _answer.won == true) {
            revert invalidAnswerData(_questionId);
        }

        // Generating the quesion id using the generateId
        // function from the IdGenerator.sol
        _answer.id = IdGenerator.generateId(msg.sender);
        answers[_answer.id] = _answer;

        emit questionAnswered(msg.sender, _questionId);
    }

    // @param: _voteType is used to validate if it's a upvote or an down vote;
    function voteForAnswer(bytes32 _answerId, VoteType _voteType) public {

        if(msg.sender == answers[_answerId].creator){ revert invalidUser(); }

        Answer memory answer = answers[_answerId];

        if(_voteType == VoteType.UPVOTE) { answer.vote++; } 
        else if (_voteType == VoteType.DOWNVOTE ){ answer.vote--; }
        else { invalidAnswerVote(); }

        answers[_answerId] = answer;
        emit answerVoted(_answerId, msg.sender);
    }

    function deleteAnswer(bytes32 _answerId) public {

        if(msg.sender != answers[_answerId].creator) {
            revert invalidUser(msg.sender);
        }

        delete answers[_answerId];
        emit answerDeleted(_answerId);
    }

    // @notice: When a user doesn't provide the winner answer the governance
    // will vote for a winner and the user that created the question will have
    // his reputation reduced!
    function createProposalForAnswerWinner(bytes32 _question) public {

    }

    // @notice: Provide a winner answer for the _question passed as param
    // by calculating the votes,  paying the reward for the winner and 
    // increasing his reputation in the platform
    function provideWinner(bytes32 _question) public {

    }

    // ========================
    // *      GOVERNANCE      *  
    // ========================
    
    // todo - Validate the request so only the governance
    // can call these functions.
    function updateFeeRate(uint256 _feeRate) public {
        if(_feeRate == 0) {
            revert invalidFeeRate(_feeRate);
        }
        feeRate = _feeRate;
        emit feeRateUpdated(_feeRate);
    }

    function updateReward(uint256 _newReward) public {
        // Calculating the percentage of use of the contract
        // balance to provide the reward.
        uint256 contractBalance = address(this).balance;
        uint256 rewardPercentage = (_newReward * 100) / contractBalance;

        if (rewardPercentage > maxReward) {
            revert invalidReward(_newReward);
        }

        reward = _newReward;
        emit rewardUpdated(_newReward);
    }

}