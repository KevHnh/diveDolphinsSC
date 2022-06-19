// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DiveDolphins is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // constant variables
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    uint256 public constant PUBLIC_SALE_PRICE = .09 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .05 ether;

    // string variables for Uri's
    string private baseTokenUri;
    string public placeholderTokenUri;

    // toggleable variables
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;

    bytes32 private merkleRoot;

    // keeps track of mints per wallet (public and whitelist)
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Dive Dolphins", "DD") {}

    // checks if caller is a user (wallet), not another smart contract 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller Cannot Be A Contract");
        _;
    }

    // mint function
    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Public Mint Not Active."); // checks if publicSale boolean is toggled on
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply"); // checks if there are enough available NFTs to mint
        require((totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT, "Beyond Mint Limit"); // checks if the buyer is within the mint limit
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Insufficient Funds"); // checks if buyer sent enough ETH
        totalPublicMint[msg.sender] += _quantity; // increments quantity of buyer
        _safeMint(msg.sender, _quantity); // calls ERC-721A safeMint function
    }

    // whitelist mint function
    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(whiteListSale, "Whitelist Mint Not Active"); // checks if whiteListSale boolean is toggled on
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply"); // checks if there are enough available NFTs to mint
        require((totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT, "Beyond Whitelist Mint Limit"); // checks if the buyer is within the mint limit
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Insufficient Funds"); // checks if buyer sent enough ETH

        // whitelist verification
        bytes32 sender = keccak256(abi.encodePacked(msg.sender)); // create hash
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You Are Not Whitelisted"); // verify whitelist

        totalWhitelistMint[msg.sender] += _quantity; // increments quantity of buyer
        _safeMint(msg.sender, _quantity); // calls ERC-721A safeMint function
    }

    // baseURI getter function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    // tokenURI retrieval function
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI Query For Non-Existent Token"); // checks if tokenId exists

        uint256 trueId = tokenId + 1; // obtains trueId

        if (!isRevealed) { // checks if isRevealed boolean is false
            return placeholderTokenUri; // placeholderTokenUri is used (hidden image)
        }

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : ""; // returns trueId 
    }

    // merkle root getter function
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    // setter functions
    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // toggle functions
    function toggleWhiteListSale() external onlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    // withdraw function
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
