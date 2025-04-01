const { ethers } = require("hardhat");
const { generateMerkleTree } = require("./merkleUtils");

async function main() {
  // Generate some random addresses for the whitelist
  const whitelistedAddresses = [
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
  ];
  
  console.log("Whitelisted addresses:");
  whitelistedAddresses.forEach(addr => console.log(` - ${addr}`));
  
  // Generate the Merkle Tree and get the root
  const { merkleTree, merkleRoot } = generateMerkleTree(whitelistedAddresses);
  console.log(`\nMerkle Root: ${merkleRoot}`);
  
  // Deploy the WhitelistedNFT contract
  const WhitelistedNFT = await ethers.getContractFactory("WhitelistedNFT");
  const nft = await WhitelistedNFT.deploy(merkleRoot);
  await nft.deployed();
  
  const address = nft.address;
  console.log(`\nWhitelistedNFT deployed to: ${address}`);
  
  return { nft, merkleTree, whitelistedAddresses };
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { main }; 