// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TokenOrbitDAO
 * @dev A decentralized autonomous organization for token-based governance
 * @notice This contract manages proposals, voting, and treasury operations
 */
contract TokenOrbitDAO {
    
    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    // State variables
    address public owner;
    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    uint256 public minimumTokensToPropose = 100 * 10**18; // 100 tokens
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public memberTokens;
    mapping(address => bool) public members;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event TokensAllocated(address indexed member, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberTokens[msg.sender] = 1000 * 10**18; // Initial tokens for creator
    }
    
    /**
     * @dev Core Function 1: Create a new proposal
     * @param _description Description of the proposal
     * @return proposalId The ID of the newly created proposal
     */
    function createProposal(string memory _description) external onlyMember returns (uint256) {
        require(memberTokens[msg.sender] >= minimumTokensToPropose, "Insufficient tokens to create proposal");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + votingPeriod;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalId, msg.sender, _description);
        
        return proposalId;
    }
    
    /**
     * @dev Core Function 2: Vote on a proposal
     * @param _proposalId The ID of the proposal to vote on
     * @param _support True for yes, false for no
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 votingWeight = memberTokens[msg.sender];
        require(votingWeight > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, votingWeight);
    }
    
    /**
     * @dev Core Function 3: Execute a proposal after voting period
     * @param _proposalId The ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        proposal.executed = true;
        bool passed = proposal.votesFor > proposal.votesAgainst;
        
        emit ProposalExecuted(_proposalId, passed);
    }
    
    // Helper functions
    
    /**
     * @dev Add a new member to the DAO
     * @param _member Address of the new member
     * @param _tokens Initial token allocation
     */
    function addMember(address _member, uint256 _tokens) external onlyOwner {
        require(_member != address(0), "Invalid address");
        require(!members[_member], "Already a member");
        
        members[_member] = true;
        memberTokens[_member] = _tokens;
        
        emit TokensAllocated(_member, _tokens);
    }
    
    /**
     * @dev Deposit funds to DAO treasury
     */
    function depositFunds() external payable {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Get proposal details
     * @param _proposalId The ID of the proposal
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.deadline,
            proposal.executed
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     */
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }
    
    /**
     * @dev Get contract balance
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Receive function to accept ETH
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
