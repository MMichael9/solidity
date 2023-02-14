//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract CrowdFunding {

    mapping(address => uint) public contributors;
    address public admin;
    uint public numOfContributors;
    uint public minContribution;
    uint public deadline;
    uint public goal;
    uint public amountRaised;
    
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numOfVoters;
        mapping(address=>bool) voters;        
    }

    mapping(uint=>Request) public requests;
    uint public numOfRequests;

    event Contribute(address _sender, uint _value);
    event CreateRequest(string _description, address _recipient, uint _value);
    event Payment(address _recipient, uint _value);

    constructor(uint _goal, uint _deadline) {
        admin = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value >= minContribution, "Not enough wei!");

        if(contributors[msg.sender] == 0) {
            numOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        amountRaised += msg.value;

        emit Contribute(msg.sender, msg.value);
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && amountRaised < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);

        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numOfRequests];
        numOfRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numOfVoters = 0;

        emit CreateRequest(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNumber) public {
        require(contributors[msg.sender] > 0, "You must be a contributor");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.numOfVoters++;
    }

    function makePayment(uint _requestNumber) public onlyAdmin {
        require(amountRaised >= goal);
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed == false);
        require(thisRequest.numOfVoters > numOfContributors / 2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit Payment(thisRequest.recipient, thisRequest.value);
    }
}