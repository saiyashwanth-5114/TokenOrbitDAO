// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleDAO {
    address public owner;
    uint256 public proposalCount;

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

    // Mapping from proposal ID to Proposal struct
    mapping(uint256 => Proposal) private proposals;

    // Member token balances
    mapping(address => uint256) public memberTokens;

    // Membership status
    mapping(address => bool) public members;

    // Events
    event TokensAllocated(address indexed member, uint256 tokens);
    event FundsDeposited(address indexed sender, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voterTokens);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

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
        memberTokens[msg.sender] = 1000 * 10**18; // Initial tokens for owner
        proposalCount = 0;
    }

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
     * @dev Create a new proposal
     * @param _description Description of the proposal
     * @param _votingPeriod Duration in seconds for voting period
     */
    function createProposal(string memory _description, uint256 _votingPeriod) external onlyMember returns (uint256) {
        require(bytes(_description).length > 0, "Description required");
        require(_votingPeriod > 0, "Voting period must be positive");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = _description;
        p.deadline = block.timestamp + _votingPeriod;
        p.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, _description, p.deadline);

        return proposalCount;
    }

    /**
     * @dev Vote on an active proposal
     * @param _proposalId ID of the proposal
     * @param _support True for vote in favor, false for vote against
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 voterTokens = memberTokens[msg.sender];
        require(voterTokens > 0, "No tokens to vote with");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += voterTokens;
        } else {
            proposal.votesAgainst += voterTokens;
        }

        emit Voted(_proposalId, msg.sender, _support, voterTokens);
    }

    /**
     * @dev Execute proposal if voting deadline has passed and not executed yet
     * Note: This example does not implement proposal actions — placeholder for extension
     * @param _proposalId The ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.deadline, "Voting still ongoing");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        bool success = proposal.votesFor > proposal.votesAgainst;

        // Placeholder for executing proposal actions based on result
        // For example: transfer funds, modify state, etc.
        // This contract does not implement specific actions.

        emit ProposalExecuted(_proposalId, success);
    }

    /**
     * @dev Get proposal details
     * @param _proposalId The ID of the proposal
     */
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 deadline,
            bool executed
        )
    {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

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
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

        return proposals[_proposalId].hasVoted[_voter];
    }

    /**
     * @dev Get contract balance (treasury)
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Receive function to accept ETH sent directly
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
