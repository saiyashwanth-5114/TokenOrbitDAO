Struct to represent a proposal
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
    
    100 tokens
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public memberTokens;
    mapping(address => bool) public members;
    
    Modifiers
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
        memberTokens[msg.sender] = 1000 * 10**18; Helper functions
    
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
// 
update
// 
