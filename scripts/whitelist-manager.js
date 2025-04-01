#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { generateMerkleTree, getMerkleProof } = require('./merkleUtils');

// Path where we'll store the whitelist addresses
const WHITELIST_PATH = path.join(__dirname, '../data/whitelist.json');

// Make sure the data directory exists
if (!fs.existsSync(path.dirname(WHITELIST_PATH))) {
  fs.mkdirSync(path.dirname(WHITELIST_PATH), { recursive: true });
}

// Initialize whitelist if it doesn't exist
if (!fs.existsSync(WHITELIST_PATH)) {
  fs.writeFileSync(WHITELIST_PATH, JSON.stringify([], null, 2));
}

/**
 * Read the current whitelist
 */
function getWhitelist() {
  const data = fs.readFileSync(WHITELIST_PATH, 'utf8');
  return JSON.parse(data);
}

/**
 * Save the whitelist
 */
function saveWhitelist(addresses) {
  fs.writeFileSync(WHITELIST_PATH, JSON.stringify(addresses, null, 2));
}

/**
 * Add an address to the whitelist
 */
function addAddress(address) {
  if (!address.match(/^0x[a-fA-F0-9]{40}$/)) {
    console.error('Invalid Ethereum address format');
    return;
  }
  
  const whitelist = getWhitelist();
  if (whitelist.includes(address)) {
    console.log(`Address ${address} is already whitelisted`);
    return;
  }
  
  whitelist.push(address);
  saveWhitelist(whitelist);
  
  console.log(`Address ${address} added to whitelist`);
}

/**
 * Remove an address from the whitelist
 */
function removeAddress(address) {
  const whitelist = getWhitelist();
  const newWhitelist = whitelist.filter(a => a !== address);
  
  if (whitelist.length === newWhitelist.length) {
    console.log(`Address ${address} was not in the whitelist`);
    return;
  }
  
  saveWhitelist(newWhitelist);
  console.log(`Address ${address} removed from whitelist`);
}

/**
 * List all whitelisted addresses
 */
function listAddresses() {
  const whitelist = getWhitelist();
  
  if (whitelist.length === 0) {
    console.log('Whitelist is empty');
    return;
  }
  
  console.log('Whitelisted addresses:');
  whitelist.forEach((address, i) => {
    console.log(`${i + 1}. ${address}`);
  });
}

/**
 * Generate and print the Merkle Root
 */
function generateRoot() {
  const whitelist = getWhitelist();
  
  if (whitelist.length === 0) {
    console.log('Whitelist is empty. Add addresses first.');
    return;
  }
  
  const { merkleRoot } = generateMerkleTree(whitelist);
  console.log('\nMerkle Root:');
  console.log(merkleRoot);
  console.log('\nUse this value when deploying your contract.');
}

/**
 * Generate a proof for a specific address
 */
function generateProof(address) {
  const whitelist = getWhitelist();
  
  if (!whitelist.includes(address)) {
    console.log(`Address ${address} is not in the whitelist`);
    return;
  }
  
  const { merkleTree } = generateMerkleTree(whitelist);
  const proof = getMerkleProof(merkleTree, address);
  
  console.log(`\nMerkle Proof for ${address}:`);
  console.log(JSON.stringify(proof, null, 2));
}

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];
const param = args[1];

switch (command) {
  case 'add':
    if (!param) {
      console.log('Usage: node whitelist-manager.js add <ethereum_address>');
      break;
    }
    addAddress(param);
    break;
    
  case 'remove':
    if (!param) {
      console.log('Usage: node whitelist-manager.js remove <ethereum_address>');
      break;
    }
    removeAddress(param);
    break;
    
  case 'list':
    listAddresses();
    break;
    
  case 'root':
    generateRoot();
    break;
    
  case 'proof':
    if (!param) {
      console.log('Usage: node whitelist-manager.js proof <ethereum_address>');
      break;
    }
    generateProof(param);
    break;
    
  default:
    console.log(`
Whitelist Manager for Merkle Tree NFT

Usage:
  node whitelist-manager.js <command> [params]

Commands:
  add <address>    - Add an Ethereum address to the whitelist
  remove <address> - Remove an address from the whitelist
  list             - List all whitelisted addresses
  root             - Generate and display the Merkle Root
  proof <address>  - Generate a Merkle Proof for a specific address
    `);
} 