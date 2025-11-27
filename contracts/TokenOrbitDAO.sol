// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TokenOrbitDAO
 * @dev Minimal token-weighted DAO for proposals and voting
 * @notice Voting power is proportional to ERC20 token balance at voting time
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenOrbitDAO {
    IERC20 public governanceToken;
    address public owner;

    uint256 public proposalCount;
    uint256 public votingPeriod;  // in seconds
    uint256 public quorum;        // minimum total votes (in token units) to be valid

    struct Proposal {
        uint256 id;
        address proposer;
        string  title;
        string  description;
        uint256 createdAt;
        uint256 deadline;
        uint256 forVotes;
        uint256 againstVotes;
        bool    executed;
        bool    canceled;
    }

    // proposalId => Proposal
    mapping(uint256 => Proposal) public proposals;

    // proposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        string title,
        uint256 createdAt,
        uint256 deadline
    );

    event VoteCast(
        uint256 indexed id,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed id, bool passed);
    event ProposalCanceled(uint256 indexed id);
    event ParamsUpdated(uint256 votingPeriod, uint256 quorum);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier proposalExists(uint256 id) {
        require(proposals[id].proposer != address(0), "Proposal not found");
        _;
    }

    constructor(
        address _token,
        uint256 _votingPeriod,
        uint256 _quorum
    ) {
        require(_token != address(0), "Zero token");
        require(_votingPeriod > 0, "votingPeriod = 0");

        governanceToken = IERC20(_token);
        owner = msg.sender;
        votingPeriod = _votingPeriod;
        quorum = _quorum;
    }

    /**
     * @dev Create a new proposal
     * @param title Short title
     * @param description Long-form description or IPFS link
     */
    function createProposal(
        string calldata title,
        string calldata description
    ) external returns (uint256 id) {
        id = proposalCount;
        proposalCount += 1;

        proposals[id] = Proposal({
            id: id,
            proposer: msg.sender,
            title: title,
            description: description,
            createdAt: block.timestamp,
            deadline: block.timestamp + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(
            id,
            msg.sender,
            title,
            block.timestamp,
            block.timestamp + votingPeriod
        );
    }

    /**
     * @dev Cast a vote on a proposal
     * @param id Proposal id
     * @param support True = vote for, False = vote against
     */
    function vote(uint256 id, bool support)
        external
        proposalExists(id)
    {
        Proposal storage p = proposals[id];

        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.canceled, "Proposal canceled");
        require(!p.executed, "Proposal executed");
        require(!hasVoted[id][msg.sender], "Already voted");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        hasVoted[id][msg.sender] = true;

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit VoteCast(id, msg.sender, support, weight);
    }

    /**
     * @dev Execute a proposal after voting period
     * In this minimal version, "execution" just records whether it passed.
     */
    function executeProposal(uint256 id)
        external
        proposalExists(id)
    {
        Proposal storage p = proposals[id];

        require(block.timestamp >= p.deadline, "Voting not ended");
        require(!p.executed, "Already executed");
        require(!p.canceled, "Proposal canceled");

        uint256 totalVotes = p.forVotes + p.againstVotes;
        bool passed = totalVotes >= quorum && p.forVotes > p.againstVotes;

        p.executed = true;

        emit ProposalExecuted(id, passed);
    }

    /**
     * @dev Cancel a proposal (only proposer or owner)
     */
    function cancelProposal(uint256 id)
        external
        proposalExists(id)
    {
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        require(!p.canceled, "Already canceled");
        require(msg.sender == p.proposer || msg.sender == owner, "Not authorized");

        p.canceled = true;
        emit ProposalCanceled(id);
    }

    /**
     * @dev Update DAO parameters
     */
    function updateParams(uint256 _votingPeriod, uint256 _quorum)
        external
        onlyOwner
    {
        require(_votingPeriod > 0, "votingPeriod = 0");
        votingPeriod = _votingPeriod;
        quorum = _quorum;
        emit ParamsUpdated(_votingPeriod, _quorum);
    }

    /**
     * @dev Transfer ownership of DAO admin functions
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }

    /**
     * @dev Helper: get basic proposal info
     */
    function getProposal(uint256 id)
        external
        view
        proposalExists(id)
        returns (
            address proposer,
            string memory title,
            string memory description,
            uint256 createdAt,
            uint256 deadline,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed,
            bool canceled
        )
    {
        Proposal memory p = proposals[id];
        return (
            p.proposer,
            p.title,
            p.description,
            p.createdAt,
            p.deadline,
            p.forVotes,
            p.againstVotes,
            p.executed,
            p.canceled
        );
    }
}
