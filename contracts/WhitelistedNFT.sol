// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistedNFT is ERC721, Ownable {
    bytes32 public merkleRoot;
    uint256 public tokenId;
    uint256 public MAX_SUPPLY = 1000;
    mapping(address => bool) public hasMinted;

    constructor(bytes32 _merkleRoot) ERC721("WhitelistedNFT", "WNFT") Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint(bytes32[] calldata _merkleProof) external {
        require(tokenId < MAX_SUPPLY, "Max supply reached");
        require(!hasMinted[msg.sender], "Address has already minted");
        
        // Create leaf node by hashing the lowercase address
        bytes32 leaf = keccak256(abi.encodePacked(address(msg.sender)));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");
        
        hasMinted[msg.sender] = true;
        _mint(msg.sender, tokenId);
        tokenId++;
    }

    function isWhitelisted(address _account, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
} 