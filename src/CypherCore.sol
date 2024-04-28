//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CypherGov.sol";
import "./token/CypherToken.sol";
import "./types/Question.sol";
import "./types/Answer.sol";
import "./types/User.sol";
import "./library/IdGenerator.sol";

// @author: Dave
// CypherCore is the contract that manages almost all the 
// functionalities of the platform except for the governance.
contract CypherCore {

    // ========================
    // *       STORAGE        *  
    // ========================

    address public creator;
    uint256 public feeRate;
    uint256 public rewardRate;

    CypherGov public cypherGov;
    CypherToken public CypherToken;
    
    mapping(address => User) public users;
    mapping(bytes32 => Answer) public answers;
    mapping(bytes32 => Question) public questions;

    // ========================
    // *        ENUM          *  
    // ========================

    // VoteType is used by the users to vote to answers
    enum VoteType {
        UPVOTE,
        DOWNVOTE
    }

    // SourceSelect is used by the modifier "onlyCreatorAndGov"
    // to know which mapping it should use
    enum SourceSelect {
        USERS,
        ANSWERS,
        QUESTIONS
    }

    // ========================
    // *    EVENTS & ERRORS   *  
    // ========================

    event questionCreated(address _creator, bytes32 _questionId);
    event questionAnswered(address _user, bytes32 _questionId);
    event questionDeleted(bytes32 _questionId);

    event answerWon(address _user, bytes32 _answerId);
    event answerVoted(bytes32 _currentVote, address _voter);
    event answerDeleted(bytes32 _answerId);

    event feeRateUpdated(uint256 _newFee);
    event rewardUpdated(uint256 _newReward);

    event newUserCreated(address _userAddress);
    event newGovMember(address _userAddress);
    event userRemoved(address _userAddress);

    error invalidParams();
    error invalidFeeRate(uint256 _feeRate);
    error invalidReward(uint256 _newReward);
    error invalidUser(address _user);
    error invalidAnswerData(bytes32 _questionId);
    error invalidAnswerVote();
    error invalidQuestion(bytes32 _question);
    error questionAlreadyResolved(bytes32 _questionId);

    // ========================
    // *      MODIFIERS       *  
    // ========================

    modifier onlyUser {
        require(msg.sender == users[msg.sender].userAddress, "Invalid Sender");
    }

    modifier onlyGov {
        require(msg.sender == address(cypherGov), "Invalid Sender");
        _;
    }

    modifier onlyUserAndGov {
        require(msg.sender == users[msg.sender].userAddress || msg.sender == address(cypherGov), "Invalid Sender");
        _;
    }

    modifier onlyThisContract {
        require(msg.sender == address(this), "Invalid Sender");
        _;
    }

    // @param: "_sourceSelect" represent which mapping the modifier should look
    // to validate the sender
    modifier onlyCreatorAndGov(bytes32 _id, SourceSelect _sourceSelect) {
        if(_sourceSelect == SourceSelect.ANSWERS) {
            require(msg.sender == questions[_id].creator || msg.sender == address(cypherGov));
        } else if (_sourceSelect == SourceSelect.QUESTIONS) {
            require(msg.sender == questions[_id].creator || msg.sender == address(cypherGov));
        } else if (_sourceSelect == SourceSelect.USERS) {
            require(msg.sender == users[msg.sender].userAddress || msg.sender == address(cypherGov));
        }
        _;
    }
    
    // ===========================
    // * CONSTRUCTOR & FUNCTIONS *  
    // ===========================

    constructor(uint256 _feeRate, uint256 _reward, uint256 _rewardRate) {
        creator = msg.sender;
        feeRate = _feeRate;
        reward = _reward;
        rewardRate = _rewardRate;
        cypherToken = new CypherToken(10000000);
        cypherGov = new CypherGov((this), cypherToken);
    }

    function getUser(address _userAddress) view public {
        return users[_userAddress];
    }

    function createUser(string memory _username) public {
        require(users[msg.sender].id == 0, "There's already a user with this address");
        users[msg.sender] = User({
            username: _username,
            userAddress: msg.sender,
            amountStaked: 0,
            rewards: 0,
            reputation: 0,
            govMember: false
        });

        emit newUserCreated(msg.sender, _username);
    }

    function deleteUser() onlyCreatorAndGov(0, SourceSelect.USERS) public {
        delete users[msg.sender];
        emit userRemoved(msg.sender);
    }

    function getQuestion(bytes32 _questionId) public view {
        return questions[_questionId];
    }

    function createQuestion(Question memory _question) onlyUser public {
        if (msg.sender != _question.creator) { revert invalidUser(msg.sender); }

        // Generating the quesion id using the generateId
        // function from the IdGenerator.sol
        _question.id = IdGenerator.generateId(msg.sender);
        questions[_question.id] = _question;
        emit questionCreated(msg.sender, _question.id);
    }

    function deleteQuestion(bytes32 _questionId) onlyCreatorAndGov(_questionId, SourceSelect.QUESTIONS) public {
        delete questions[_questionId];
        emit questionDeleted(_questionId);
    }

    function answerQuestion(Answer memory _answer, bytes32 _questionId) onlyUser public {
        Question memory question = questions[_questionId];

        if (question.resolved == true) { 
            revert questionAlreadyResolved(_questionId); 
        } 
        else if (question.creator == _answer.creator || msg.sender != _answer.creator) {
            revert invalidUser(msg.sender);
        }
        else if (_answer.vote != 0 || _answer.won == true) {
            revert invalidAnswerData(_questionId);
        }

        // Generating the answer id using the generateId
        // function from the IdGenerator.sol
        _answer.id = IdGenerator.generateId(msg.sender);
        _answer.createdAt = block.timestamp;
        answers[_answer.id] = _answer;
        question.answers.push(_answer);
        questions[_questionId] = question;
        emit questionAnswered(msg.sender, _questionId);
    }

    // @param: _voteType is used to validate if it's a upvote or an down vote;
    function voteForAnswer(bytes32 _answerId, VoteType _voteType) onlyUser public {
        if(msg.sender == answers[_answerId].creator){ revert invalidUser(); }

        Answer memory answer = answers[_answerId];

        if (_voteType == VoteType.UPVOTE) { answer.vote++; } 
        else if (_voteType == VoteType.DOWNVOTE ) { answer.vote--; }
        else { invalidAnswerVote(); }

        answers[_answerId] = answer;
        emit answerVoted(_answerId, msg.sender);
    }

    function deleteAnswer(bytes32 _answerId) onlyCreatorAndGov(_answerId, SourceSelect.ANSWERS) public {
        if(msg.sender != answers[_answerId].creator) { revert invalidUser(msg.sender); }
        delete answers[_answerId];
        emit answerDeleted(_answerId);
    }

    // Provide a winner answer for the question informed by
    // calculating the votes,  paying the reward for the winner and 
    // increasing his reputation in the platform, this functions is also
    // used by the users in case the creator of the question doesn't 
    // provide a winner answer.
    // @param: The _answerId is only used in case that the creator of the
    // question is the sender, otherwise the function will calculate the
    // winner by automatically.
    function provideWinner(bytes32 _question, bytes32 _answerId) onlyUserAndGov public {
        Answer memory answerWon;
        Question memory question = questions[_question];

        require(question.resolved == false, "Question already resolved");

        if (msg.sender != question.creator && _answerId == 0) {
            // Calculate the winner answers automatically and 
            // return the answer with highest vote
            answerWon = calculateVotes(question.answers);

            // Updating the reputation of the question creator
            User memory questionCreator = users[question.creator];
            questionCreator.reputation = questionCreator.reputation - answerWon.vote * rewardRate;
            users[question.creator] = questionCreator;
        } 
        else if (msg.sender == question.creator && _answerId != 0) {
            // Find the answer that the user informed as winner
            for (uint256 i = 0; i != question.answers.size(); i++) {
                if (question.answers[i].id == _answerId) {
                    answerWon = question.answers[i];
                }
            }
            // Updating the reputation of the question creator
            User memory questionCreator = users[question.creator];
            questionCreator.reputation = questionCreator.reputation + answerWon.vote * rewardRate;
            users[question.creator] = questionCreator;
        } else { revert invalidParams(); } // revert an error in case the params are invalid

        // Update the question as "resolved"
        question.resolved = true;
        questions[_question] = question;

        // Transfer the reward for the winner and update his reputation
        User memory winner = users[answerWon.creator];
        winner.reputation = winner.reputation + answerWon.vote * rewardRate;
        uint256 rewardAmount = answerWon.vote * rewardRate;
        transfer(winner.userAddress, rewardAmount);
        emit answerWon(winner.userAddress, answerWon.id);
    }

    // @notice: This function is used in the "provideWinner" function.
    // Calculate the votes and return the answer with the highest number of votes
    function calculateVotes(Answer[] _answers) onlyThisContract public {
        Answer memory winningAnswer;
        uint256 previousVoteValue = 0;

        for (uint256 i = 0; i != _answers.size(); i++) {
            Answer memory currentAnswer = _answers[i];
            if (currentAnswer.vote > winningAnswer.vote) {
                winningAnswer = currentAnswer;    
            } else if (currentAnswer.vote == winningAnswer.vote) {
                // In case answers draw the oldest one will be the winner.
                if (currentAnswer.createdAt > winningAnswer.createdAt) {
                    winningAnswer = currentAnswer;
                }
            }
        }
        return winningAnswer;
    }

    // ========================
    // *      GOVERNANCE      *  
    // ========================   

    // It will update the user turning it into a governance member
    function updateUserGov(address _userAddress, uint256 _amountStaked) onlyGov public {
        User memory newGovMember = users[_userAddress];
        newGovMember.amountStaked = _amountStaked;
        newGovMember.govMember = true;
        users[_userAddress] = newGovMember;
    }

    function updateFeeRate(uint256 _feeRate) onlyGov public {
        if(_feeRate == 0) { revert invalidFeeRate(_feeRate); }
        feeRate = _feeRate;
        emit feeRateUpdated(_feeRate);
    }

    // This function updates the rewardRate after
    // calculating the percentage of use of the _newReward
    // accordingly to the current contract balance 
    function updateRewardRate(uint256 _newReward) onlyGov public {
        uint256 contractBalance = address(this).balance;
        uint256 rewardPercentage = (_newReward * 100) / contractBalance;
        if (rewardPercentage > rewardRate) { revert invalidReward(_newReward); }
        reward = _newReward;
        emit rewardUpdated(_newReward);
    }

}