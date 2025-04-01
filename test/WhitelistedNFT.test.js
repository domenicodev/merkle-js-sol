const { expect } = require("chai");
const { ethers } = require("hardhat");
const { generateMerkleTree, getMerkleProof } = require("../scripts/merkleUtils");

describe("WhitelistedNFT", function () {
  let owner;
  let whitelisted;
  let nonWhitelisted;
  let nftContract;
  let merkleTree;
  let merkleRoot;
  let whitelistedAddresses;

  beforeEach(async function () {
    // Get signers
    [owner, whitelisted, nonWhitelisted, ...others] = await ethers.getSigners();
    
    // Create a whitelist with the whitelisted user's address
    whitelistedAddresses = [
      owner.address,
      whitelisted.address,
      // Add more addresses as needed
    ];
    
    // Generate the Merkle Tree and root
    const merkleData = generateMerkleTree(whitelistedAddresses);
    merkleTree = merkleData.merkleTree;
    merkleRoot = merkleData.merkleRoot;
    
    // Deploy the contract
    const WhitelistedNFT = await ethers.getContractFactory("WhitelistedNFT");
    nftContract = await WhitelistedNFT.deploy(merkleRoot);
  });

  describe("Whitelist verification", function () {
    it("should correctly identify whitelisted addresses", async function () {
      // Get the Merkle Proof for the whitelisted address
      const proof = getMerkleProof(merkleTree, whitelisted.address);
      
      // Verify that the whitelisted address is indeed whitelisted
      const isWhitelisted = await nftContract.isWhitelisted(whitelisted.address, proof);
      expect(isWhitelisted).to.be.true;
    });

    it("should correctly reject non-whitelisted addresses", async function () {
      // Get a proof for the non-whitelisted address (this will be invalid)
      const proof = getMerkleProof(merkleTree, whitelisted.address);  // Using wrong proof on purpose
      
      // Verify that the non-whitelisted address is rejected
      const isWhitelisted = await nftContract.isWhitelisted(nonWhitelisted.address, proof);
      expect(isWhitelisted).to.be.false;
    });
  });

  describe("Minting functionality", function () {
    it("should allow whitelisted users to mint", async function () {
      const proof = getMerkleProof(merkleTree, whitelisted.address);
      
      // Mint a token as the whitelisted user
      await nftContract.connect(whitelisted).mint(proof);
      
      // Check that the token was minted to the correct address
      expect(await nftContract.ownerOf(0)).to.equal(whitelisted.address);
    });

    it("should prevent non-whitelisted users from minting", async function () {
      // Try to mint with a wrong proof
      const wrongProof = getMerkleProof(merkleTree, whitelisted.address);
      
      // The transaction should revert
      await expect(
        nftContract.connect(nonWhitelisted).mint(wrongProof)
      ).to.be.revertedWith("Invalid proof");
    });

    it("should prevent users from minting more than once", async function () {
      const proof = getMerkleProof(merkleTree, whitelisted.address);
      
      // Mint once successfully
      await nftContract.connect(whitelisted).mint(proof);
      
      // Try to mint again, should fail
      await expect(
        nftContract.connect(whitelisted).mint(proof)
      ).to.be.revertedWith("Address has already minted");
    });
  });
}); 