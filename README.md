# NFT Whitelist with Merkle Proofs

This project demonstrates how to implement a whitelist system for NFT minting using Merkle trees and proofs.

## Overview

The project consists of:
- A Solidity contract (`WhitelistedNFT`) that implements an ERC721 token with whitelist verification using Merkle proofs
- JavaScript utility functions for generating Merkle trees and proofs from a list of addresses
- Test scripts to verify the functionality
- A CLI utility to manage the whitelist and generate proofs

## Installation

```bash
npm install
```

## Compile Contracts

```bash
npm run compile
```

## Run Tests

```bash
npm test
```

## Deploy Contracts

```bash
npm run deploy
```

## Interacting with Contracts

```bash
npm run interact
```

## Managing the Whitelist

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

## How It Works

1. We create a list of whitelisted addresses
2. Generate a Merkle tree where each leaf is a hashed Ethereum address
3. Store only the Merkle root in the smart contract
4. When a user wants to mint an NFT, they provide a Merkle proof that verifies their address is part of the whitelist
5. The contract verifies the proof and allows minting if valid

## Key Files

- `contracts/WhitelistedNFT.sol`: The main NFT contract with Merkle verification
- `scripts/merkleUtils.js`: Utility functions for Merkle tree operations
- `scripts/deploy.js`: Deployment script
- `scripts/interact.js`: Script to interact with the deployed contract
- `scripts/whitelist-manager.js`: CLI utility for managing the whitelist
- `test/WhitelistedNFT.test.js`: Tests for the contract

## Security Considerations

- The Merkle root is immutable once set, but can be updated by the contract owner
- Each address can only mint once
- The contract has a max supply cap
