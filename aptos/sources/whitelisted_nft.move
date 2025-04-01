module whitelist_nft::whitelisted_nft {
    use std::error;
    use std::signer;
    use std::string::String;
    use std::vector;
    
    use aptos_std::bcs;
    use aptos_std::hash;

    use whitelist_nft::merkle_proof;

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_ALREADY_MINTED: u64 = 2;
    const E_INVALID_PROOF: u64 = 3;
    const E_MAX_SUPPLY_REACHED: u64 = 4;
    const E_COLLECTION_NOT_INITIALIZED: u64 = 5;

    /// Resource to track owned NFTs
    struct NFT has key, store {
        /// The token's name
        name: String,
        /// The token's description
        description: String,
        /// The token's URI
        uri: String,
        /// Token number in the collection
        token_id: u64,
        /// Creator of the NFT collection
        creator: address,
    }

    /// Resource to store collection configuration
    struct CollectionConfig has key {
        /// The merkle root for the whitelist
        merkle_root: vector<u8>,
        /// Current number of tokens minted
        token_count: u64,
        /// Maximum supply of tokens
        max_supply: u64,
        /// Addresses that have minted
        minted: vector<address>,
    }

    /// Initialize the collection
    public entry fun initialize_collection(
        creator: &signer,
        _collection_name: String,
        _collection_description: String,
        _collection_uri: String,
        merkle_root: vector<u8>,
        max_supply: u64
    ) {
        // Move the collection config to the creator's account
        move_to(creator, CollectionConfig {
            merkle_root,
            token_count: 0,
            max_supply,
            minted: vector::empty<address>(),
        });
    }

    /// Update the merkle root (only the collection creator can do this)
    public entry fun update_merkle_root(
        admin: &signer,
        collection_creator: address,
        new_merkle_root: vector<u8>
    ) acquires CollectionConfig {
        // Only the collection creator can update the merkle root
        assert!(signer::address_of(admin) == collection_creator, error::permission_denied(E_NOT_AUTHORIZED));
        
        let config = borrow_global_mut<CollectionConfig>(collection_creator);
        config.merkle_root = new_merkle_root;
    }

    /// Mint a token to a whitelisted address
    public entry fun mint(
        recipient: &signer,
        collection_creator: address,
        merkle_proof: vector<vector<u8>>,
        token_name: String,
        token_description: String,
        token_uri: String
    ) acquires CollectionConfig {
        let recipient_addr = signer::address_of(recipient);
        
        // Make sure the collection exists
        assert!(exists<CollectionConfig>(collection_creator), error::not_found(E_COLLECTION_NOT_INITIALIZED));
        
        let config = borrow_global_mut<CollectionConfig>(collection_creator);
        
        // Check max supply
        assert!(config.token_count < config.max_supply, error::resource_exhausted(E_MAX_SUPPLY_REACHED));
        
        // Check if address has already minted
        let i = 0;
        let len = vector::length(&config.minted);
        let already_minted = false;
        
        while (i < len) {
            if (*vector::borrow(&config.minted, i) == recipient_addr) {
                already_minted = true;
                break
            };
            i = i + 1;
        };
        
        assert!(!already_minted, error::already_exists(E_ALREADY_MINTED));
        
        // Create the leaf for verification (hash of recipient address)
        let recipient_bytes = bcs::to_bytes(&recipient_addr);
        let leaf = hash::sha3_256(recipient_bytes);
        
        // Verify the merkle proof
        assert!(
            merkle_proof::verify(merkle_proof, config.merkle_root, leaf),
            error::invalid_argument(E_INVALID_PROOF)
        );
        
        // Mint the token by adding it to the recipient's account
        let token_id = config.token_count;
        
        // Create and move the NFT to the recipient's account
        move_to(recipient, NFT {
            name: token_name,
            description: token_description,
            uri: token_uri,
            token_id,
            creator: collection_creator,
        });
        
        // Update collection state
        config.token_count = config.token_count + 1;
        vector::push_back(&mut config.minted, recipient_addr);
    }
    
    /// Check if an address is whitelisted
    public fun is_whitelisted(
        addr: address,
        collection_creator: address,
        merkle_proof: vector<vector<u8>>
    ): bool acquires CollectionConfig {
        let config = borrow_global<CollectionConfig>(collection_creator);
        
        // Create the leaf for verification
        let addr_bytes = bcs::to_bytes(&addr);
        let leaf = hash::sha3_256(addr_bytes);
        
        // Verify the merkle proof
        merkle_proof::verify(merkle_proof, config.merkle_root, leaf)
    }
} 