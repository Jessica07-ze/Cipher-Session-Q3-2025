// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {
    event GoalCreated(uint256 id, string name, address creator);
    event ContributionReceived(uint256 id, uint256 amount, address contributor);
    event GoalCompleted(uint256 id);
    event PanicWithdrawal(uint256 id, uint256 amount, address contributor);

    struct Goal {
        uint256 id;
        string name;
        uint256 amount;
        uint256 raisedAmount;
        address creator;
        uint256 deadline;
        uint256 createdAt;
        bool completed;
    }
    Goal[] public goals;
    mapping(uint256 => address[]) public goalToContributors;
    mapping(address => mapping(uint256 => uint256)) public contributorToAmountContributed;

    // create crowdfund
    function createCrowdFund(
        string calldata name_,
        uint256 amount_,
        uint256 deadline_
    ) public {
        uint256 id_ = goals.length;

        goals.push(
            Goal({
                id: id_,
                name: name_,
                amount: amount_,
                raisedAmount: 0,
                creator: msg.sender,
                deadline: deadline_,
                createdAt: block.timestamp,
                completed: false
            })
        );

        emit GoalCreated(id_, name_, msg.sender);
    }

    // get crowdfund details
    function getCrowdFund(uint256 id) public view returns (Goal memory) {
        Goal memory goal = goals[id];

        return goal;
    }

    // contribute to a crowdfund
    function contribute(uint256 id_) public payable {
        uint256 amount_ = msg.value;

        require(amount_ > 0, "Invalid Amount");

        address contributor_ = msg.sender;

        Goal storage goal = goals[id_];

        require(!goal.completed, "Goal already Completed");

        goal.raisedAmount += amount_;

        contributorToAmountContributed[contributor_][id_] += amount_;
        if (contributorToAmountContributed[contributor_][id_] == amount_) {
            goalToContributors[id_].push(contributor_);
        }

        emit ContributionReceived(id_, amount_, contributor_);
    }

    // withdraw from crowdfund
    function withdrawCrowdFund(uint256 id_) public {
        Goal storage goal = goals[id_];

        require(
            goal.creator != address(0) && goal.creator == msg.sender,
            "Unauthorized"
        );
        require(!goal.completed, "Goal already Completed");
        goal.completed = true;

        (bool sent, ) = (msg.sender).call{value: goal.amount}("");
        require(sent, "Withdrawal Failed");

        emit GoalCompleted(id_);
    }

    // withdraw on failure
    function withdrawFailed(uint256 id_) public {
        Goal storage goal = goals[id_];

        require(goal.creator != address(0), "Invalid Goal");
        require(!goal.completed, "Goal already completed");
        require(
            (goal.deadline + goal.createdAt) < block.timestamp,
            "Deadline has not passed"
        );

        uint256 amount = contributorToAmountContributed[msg.sender][id_];
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdrawal Failed");

        emit PanicWithdrawal(id_, amount, msg.sender);
    }
}
