//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

    error invalidUser(address _user);
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

    mapping(address => User) public users;
    mapping(bytes32 => Answer) public answers;
    mapping(bytes32 => Question) public questions;

    constructor() {
        creator = msg.sender;
        // TODO - Create governance contract
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
        
        if(msg.sender != _answer.creator) {
            revert invalidUser(msg.sender);
        } else if(questions[_questionId].resolved == true) {
            revert questionAlreadyResolved(_questionId);
        }

        if (_answer.vote != 0) {
            _answer.vote = 0;
        } else if (_answer.won == true) {
            _answer.won = false;
        }

        // Generating the quesion id using the generateId
        // function from the IdGenerator.sol
        _answer.id = IdGenerator.generateId(msg.sender);
        answers[_answer.id] = _answer;
        emit questionAnswered(msg.sender, _questionId);
    }

    // @param: _voteType is used to validate if it's a upvote or an down vote;
    function voteForAnswer(bytes32 _answerId, VoteType _voteType) public {
        if(msg.sender == answers[_answerId].creator){
            revert invalidAnswerVote();
        }
        Answer memory answer = answers[_answerId];
        if(_voteType == VoteType.UPVOTE) {
            answer.vote++;
        } else {
            answer.vote--;
        }
        answers[_answerId] = answer;
        emit answerVoted(_answerId, msg.sender);
    }

    // ========================
    // *      GOVERNANCE      *  
    // ========================


    // ========================
    // *         UTIL         *  
    // ========================


}