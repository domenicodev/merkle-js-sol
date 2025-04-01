const { ethers } = require("hardhat");
const { generateMerkleTree, getMerkleProof } = require("./merkleUtils");

async function main() {
  // Get the signers
  const [deployer, user1, user2, user3] = await ethers.getSigners();
  
  console.log("Deployer address:", deployer.address);
  console.log("User1 address:", user1.address);
  console.log("User2 address:", user2.address);
  console.log("User3 address:", user3.address);
  
  // Create a whitelist with some addresses
  const whitelistedAddresses = [
    deployer.address,
    user1.address,
    user2.address
    // Note: user3 is not whitelisted
  ];
  
  console.log("\nCreating Merkle Tree with whitelisted addresses");
  const { merkleTree, merkleRoot } = generateMerkleTree(whitelistedAddresses);
  console.log("Merkle Root:", merkleRoot);
  
  // Deploy the NFT contract
  console.log("\nDeploying WhitelistedNFT contract");
  const WhitelistedNFT = await ethers.getContractFactory("WhitelistedNFT");
  const nft = await WhitelistedNFT.deploy(merkleRoot);
  await nft.deployed();
  
  // Get contract address
  const contractAddress = nft.address;
  console.log("Contract deployed at:", contractAddress);
  
  // Check if addresses are whitelisted
  console.log("\n--- Whitelist Verification ---");
  
  // Check user1 (should be whitelisted)
  const proof1 = getMerkleProof(merkleTree, user1.address);
  const isUser1Whitelisted = await nft.isWhitelisted(user1.address, proof1);
  console.log(`User1 (${user1.address}) whitelisted:`, isUser1Whitelisted);
  
  // Check user3 (should NOT be whitelisted)
  const proof3 = getMerkleProof(merkleTree, user3.address);
  const isUser3Whitelisted = await nft.isWhitelisted(user3.address, proof3);
  console.log(`User3 (${user3.address}) whitelisted:`, isUser3Whitelisted);
  
  // Mint an NFT for a whitelisted address
  console.log("\n--- NFT Minting ---");
  
  // User1 mints a token (should succeed)
  const mintTx = await nft.connect(user1).mint(proof1);
  await mintTx.wait();
  console.log(`User1 minted token ID: 0`);
  
  // User3 tries to mint a token (should fail)
  try {
    await nft.connect(user3).mint(proof3);
    console.log("User3 minted a token (this should not happen)");
  } catch (error) {
    console.log("User3 minting failed as expected:", error.message.split("\n")[0]);
  }
  
  // Try to mint again with same address (should fail)
  try {
    await nft.connect(user1).mint(proof1);
    console.log("User1 minted a second token (this should not happen)");
  } catch (error) {
    console.log("User1 second minting failed as expected:", error.message.split("\n")[0]);
  }
  
  // Display token info
  const tokenOwner = await nft.ownerOf(0);
  console.log(`\nToken ID 0 is owned by: ${tokenOwner}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  }); 