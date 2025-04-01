# NFT Whitelist with Merkle Proofs

This project demonstrates how to implement a whitelist system for NFT minting using Merkle trees and proofs on both Ethereum (Solidity) and Aptos (Move) blockchains.

## Overview

The project consists of:
- A Solidity contract (`WhitelistedNFT`) that implements an ERC721 token with whitelist verification using Merkle proofs
- A Move module for Aptos (`WhitelistedNFT`) that implements NFT minting with whitelist verification
- JavaScript utility functions for generating Merkle trees and proofs from a list of addresses
- Test scripts to verify the functionality
- A CLI utility to manage the whitelist and generate proofs

## Ethereum Implementation

### Installation

```bash
npm install
```

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
npm test
```

### Deploy Contracts

```bash
npm run deploy
```

### Interacting with Contracts

```bash
npm run interact
```

### Managing the Whitelist

The project includes a command-line utility for managing the whitelist:

```bash
npm run whitelist -- <command> [params]
```

Available commands:

- `add <address>` - Add an Ethereum address to the whitelist
- `remove <address>` - Remove an address from the whitelist
- `list` - List all whitelisted addresses
- `root` - Generate and display the Merkle Root
- `proof <address>` - Generate a Merkle Proof for a specific address

Examples:

```bash
# Add an address to the whitelist
npm run whitelist -- add 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# List all addresses
npm run whitelist -- list

# Generate the Merkle root to deploy with your contract
npm run whitelist -- root

# Generate a proof for a specific address (for minting)
npm run whitelist -- proof 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

## Aptos Implementation

The `aptos/` directory contains a Move implementation of the WhitelistedNFT concept for the Aptos blockchain.

### Building & Testing

```bash
cd aptos
aptos move compile
aptos move test --dev
```

### Key Components

- `merkle_proof.move`: Implements Merkle tree verification logic
- `whitelisted_nft.move`: Implements the main NFT functionality with whitelist verification
- `whitelisted_nft_tests.move`: Tests for the WhitelistedNFT module

### Key Features

1. ✅ Full Merkle tree whitelist verification
2. ✅ NFT minting with whitelist controls
3. ✅ Access control for updating the whitelist

### JavaScript Integration

The `scripts/generateAptosProof.js` file demonstrates how to generate Merkle proofs for use with the Aptos implementation.

```bash
node scripts/generateAptosProof.js
```

**Note:** There are currently compatibility issues between the JavaScript and Move implementations due to differences in address serialization. See the Aptos README for more details.

## How It Works

1. We create a list of whitelisted addresses
2. Generate a Merkle tree where each leaf is a hashed address
3. Store only the Merkle root in the smart contract/module
4. When a user wants to mint an NFT, they provide a Merkle proof that verifies their address is part of the whitelist
5. The contract verifies the proof and allows minting if valid

## Key Files

- `contracts/WhitelistedNFT.sol`: The Ethereum NFT contract with Merkle verification
- `aptos/sources/whitelisted_nft.move`: The Aptos NFT module with Merkle verification
- `aptos/sources/merkle_proof.move`: Merkle proof verification for Aptos
- `scripts/merkleUtils.js`: Utility functions for Merkle tree operations
- `scripts/generateAptosProof.js`: Utility to generate proofs for Aptos

## Security Considerations

- The Merkle root is immutable once set, but can be updated by the contract owner
- Each address can only mint once
- The contract has a max supply cap
