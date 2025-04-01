const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const ethers = require('ethers');

/**
 * Generates a Merkle Tree from a list of addresses
 * @param {string[]} addresses - Array of Ethereum addresses
 * @returns {Object} - { merkleTree, merkleRoot }
 */
function generateMerkleTree(addresses) {
  // Hash the addresses using keccak256
  const leaves = addresses.map(addr => keccak256(addr.toLowerCase()));
  
  // Create a new Merkle Tree
  const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  
  // Get the Merkle Root
  const merkleRoot = merkleTree.getHexRoot();
  
  return { merkleTree, merkleRoot };
}

/**
 * Gets a Merkle Proof for a specific address
 * @param {MerkleTree} merkleTree - The Merkle Tree
 * @param {string} address - Ethereum address to generate a proof for
 * @returns {string[]} - The Merkle Proof as an array of hex strings
 */
function getMerkleProof(merkleTree, address) {
  const leaf = keccak256(address.toLowerCase());
  return merkleTree.getHexProof(leaf);
}

module.exports = {
  generateMerkleTree,
  getMerkleProof
}; 