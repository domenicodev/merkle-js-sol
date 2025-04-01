const { generateMerkleTree, getMerkleProof } = require('./merkleUtils');

// Example addresses for our whitelist
const addresses = [
  '0x1',
  '0x2',
  '0x3',
  '0x4',
  '0x5'
];

// Generate the Merkle Tree
const { merkleTree, merkleRoot } = generateMerkleTree(addresses);

// Convert hex string to Move format (x"...")
function toMoveHex(hexString) {
  // Remove 0x prefix if present
  const hex = hexString.startsWith('0x') ? hexString.slice(2) : hexString;
  return `x"${hex}"`;
}

// Print the Merkle Root in Move format
console.log('Merkle Root (for Move):');
console.log(toMoveHex(merkleRoot));
console.log('');

// Generate and print proofs for each address
addresses.forEach(address => {
  const proof = getMerkleProof(merkleTree, address);
  console.log(`Proof for address ${address} (for Move):`);
  console.log('let proof = vector[');
  proof.forEach(proofElement => {
    console.log(`    ${toMoveHex(proofElement)},`);
  });
  console.log('];');
  console.log('');
});

// Example usage in Move test
console.log('Example usage in Move test:');
console.log(`
// In your test_hardcoded_js_merkle function:

// Setup merkle root from JS output
let merkle_root = ${toMoveHex(merkleRoot)};

// Initialize collection with the JS-generated Merkle root
whitelisted_nft::initialize_collection(
    creator,
    string::utf8(b"JS Whitelist Collection"),
    string::utf8(b"A collection using JS-generated Merkle root"),
    string::utf8(b"https://example.com/collection"),
    merkle_root,
    100
);

// For address 0x3, use this proof:
let proof_for_0x3 = vector[
${getMerkleProof(merkleTree, '0x3').map(p => `    ${toMoveHex(p)}`).join(',\n')}
];

// Verify the proof for address 0x3
assert!(whitelisted_nft::is_whitelisted(@0x3, creator_addr, proof_for_0x3), 0);

// This should fail for an address not in the whitelist:
assert!(!whitelisted_nft::is_whitelisted(@0x6, creator_addr, proof_for_0x3), 0);
`); 