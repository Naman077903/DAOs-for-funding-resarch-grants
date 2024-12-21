// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleDAO {
    struct Proposal {
        string description;
        address payable recipient;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    address public chairperson;
    uint256 public minimumContribution;
    uint256 public votingDuration;
    Proposal[] public proposals;

    mapping(address => uint256) public contributions;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    modifier onlyContributor() {
        require(contributions[msg.sender] > 0, "Only contributors can perform this action");
        _;
    }

    constructor(uint256 _minimumContribution, uint256 _votingDuration) {
        chairperson = msg.sender;
        minimumContribution = _minimumContribution;
        votingDuration = _votingDuration;
    }

    function contribute() external payable {
        require(msg.value >= minimumContribution, "Contribution is below the minimum amount");
        contributions[msg.sender] += msg.value;
    }

    function createAndExecuteProposal(
        string memory _description,
        address payable _recipient,
        uint256 _amount
    ) external onlyContributor {
        require(address(this).balance >= _amount, "Not enough funds available");

        Proposal memory proposal = Proposal({
            description: _description,
            recipient: _recipient,
            amount: _amount,
            votesFor: contributions[msg.sender],
            votesAgainst: 0,
            deadline: block.timestamp + votingDuration,
            executed: false
        });

        proposals.push(proposal);

        Proposal storage createdProposal = proposals[proposals.length - 1];

        if (block.timestamp >= createdProposal.deadline && !createdProposal.executed) {
            if (createdProposal.votesFor > createdProposal.votesAgainst) {
                createdProposal.executed = true;
                (bool success, ) = createdProposal.recipient.call{value: createdProposal.amount}("");
                require(success, "Transfer failed");
            }
        }
    }
}
