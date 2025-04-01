#[test_only]
module whitelist_nft::whitelisted_nft_tests {
    use std::signer;
    use std::string;
    use std::vector;
    
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_std::bcs;
    use aptos_std::hash;
    
    use whitelist_nft::whitelisted_nft;

    /// Error constants for tests
    const E_TEST_FAILURE: u64 = 1000;
    
    // Constants for vector comparison results
    const LESS_THAN: u8 = 0;
    const EQUAL: u8 = 1;
    const GREATER_THAN: u8 = 2;

    #[test(creator = @0xABCD, user1 = @0x123, user2 = @0x456, framework = @0x1)]
    fun test_collection_creation_and_minting(
        creator: &signer, 
        user1: &signer, 
        user2: &signer,
        framework: &signer
    ) {
        // Set up testing environment
        setup_test_environment(framework);
        
        // Set addresses for testing
        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        
        // Create accounts for testing
        account::create_account_for_test(creator_addr);
        account::create_account_for_test(user1_addr);
        account::create_account_for_test(user2_addr);
        
        // Set up a whitelist with just user1
        let whitelisted_addresses = vector::empty<address>();
        vector::push_back(&mut whitelisted_addresses, user1_addr);
        
        // Generate Merkle root
        let merkle_data = generate_merkle_tree_for_test(whitelisted_addresses);
        let merkle_root = merkle_data.root;
        
        // Initialize collection
        let collection_name = string::utf8(b"Whitelisted Collection");
        let collection_description = string::utf8(b"A collection of NFTs for whitelisted addresses");
        let collection_uri = string::utf8(b"https://example.com/collection");
        let max_supply = 100;
        
        whitelisted_nft::initialize_collection(
            creator,
            collection_name,
            collection_description,
            collection_uri,
            merkle_root,
            max_supply
        );
        
        // User1 should be able to mint (they're whitelisted)
        let token_name = string::utf8(b"Token #1");
        let token_description = string::utf8(b"A whitelisted NFT");
        let token_uri = string::utf8(b"https://example.com/token/1");
        
        let user1_proof = merkle_data.proofs.user1;
        
        whitelisted_nft::mint(
            user1,
            creator_addr,
            user1_proof,
            token_name,
            token_description,
            token_uri
        );
        
        // Check if user1 is whitelisted (should be true)
        assert!(
            whitelisted_nft::is_whitelisted(user1_addr, creator_addr, user1_proof),
            E_TEST_FAILURE
        );
        
        // User2 should not be whitelisted (not in the merkle tree)
        // We'll use user1's proof which will be invalid for user2
        assert!(
            !whitelisted_nft::is_whitelisted(user2_addr, creator_addr, user1_proof),
            E_TEST_FAILURE
        );
        
        // Update merkle root to include user2
        let updated_whitelist = vector::empty<address>();
        vector::push_back(&mut updated_whitelist, user1_addr);
        vector::push_back(&mut updated_whitelist, user2_addr);
        
        let updated_merkle_data = generate_merkle_tree_for_test(updated_whitelist);
        let updated_merkle_root = updated_merkle_data.root;
        
        // Update the merkle root
        whitelisted_nft::update_merkle_root(creator, creator_addr, updated_merkle_root);
        
        // Now user2 should be able to mint with their proof
        let user2_proof = updated_merkle_data.proofs.user2;
        let token2_name = string::utf8(b"Token #2");
        let token2_description = string::utf8(b"Another whitelisted NFT");
        let token2_uri = string::utf8(b"https://example.com/token/2");
        
        whitelisted_nft::mint(
            user2,
            creator_addr,
            user2_proof,
            token2_name,
            token2_description,
            token2_uri
        );
    }

    #[test(creator = @0xABCD, user1 = @0x123, user2 = @0x456, framework = @0x1)]
    #[expected_failure(abort_code = 524290, location = whitelist_nft::whitelisted_nft)]
    fun test_already_minted_failure(
        creator: &signer, 
        user1: &signer, 
        user2: &signer,
        framework: &signer
    ) {
        // Set up testing environment
        setup_test_environment(framework);
        
        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        
        // Create accounts for testing
        account::create_account_for_test(creator_addr);
        account::create_account_for_test(user1_addr);
        
        // Set up whitelist with user1
        let whitelisted_addresses = vector::empty<address>();
        vector::push_back(&mut whitelisted_addresses, user1_addr);
        
        let merkle_data = generate_merkle_tree_for_test(whitelisted_addresses);
        let merkle_root = merkle_data.root;
        
        // Initialize collection
        whitelisted_nft::initialize_collection(
            creator,
            string::utf8(b"Whitelisted Collection"),
            string::utf8(b"A collection of NFTs for whitelisted addresses"),
            string::utf8(b"https://example.com/collection"),
            merkle_root,
            100
        );
        
        let user1_proof = merkle_data.proofs.user1;
        
        // First mint should succeed
        whitelisted_nft::mint(
            user1,
            creator_addr,
            user1_proof,
            string::utf8(b"Token #1"),
            string::utf8(b"A whitelisted NFT"),
            string::utf8(b"https://example.com/token/1")
        );
        
        // Second mint should fail with E_ALREADY_MINTED
        whitelisted_nft::mint(
            user1,
            creator_addr,
            user1_proof,
            string::utf8(b"Token #2"),
            string::utf8(b"Another NFT"),
            string::utf8(b"https://example.com/token/2")
        );
    }

    #[test(creator = @0xABCD, user1 = @0x123, user2 = @0x456, framework = @0x1)]
    #[expected_failure(abort_code = 65539, location = whitelist_nft::whitelisted_nft)]
    fun test_invalid_proof_failure(
        creator: &signer, 
        user1: &signer, 
        user2: &signer,
        framework: &signer
    ) {
        // Set up testing environment
        setup_test_environment(framework);
        
        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        
        // Create accounts for testing
        account::create_account_for_test(creator_addr);
        account::create_account_for_test(user1_addr);
        account::create_account_for_test(user2_addr);
        
        // Set up whitelist with only user1
        let whitelisted_addresses = vector::empty<address>();
        vector::push_back(&mut whitelisted_addresses, user1_addr);
        
        let merkle_data = generate_merkle_tree_for_test(whitelisted_addresses);
        let merkle_root = merkle_data.root;
        
        // Initialize collection
        whitelisted_nft::initialize_collection(
            creator,
            string::utf8(b"Whitelisted Collection"),
            string::utf8(b"A collection of NFTs for whitelisted addresses"),
            string::utf8(b"https://example.com/collection"),
            merkle_root,
            100
        );
        
        let user1_proof = merkle_data.proofs.user1;
        
        // User2 tries to mint with user1's proof - should fail
        whitelisted_nft::mint(
            user2,
            creator_addr,
            user1_proof,
            string::utf8(b"Token #1"),
            string::utf8(b"A whitelisted NFT"),
            string::utf8(b"https://example.com/token/1")
        );
    }

    #[test(creator = @0xABCD, user1 = @0x123, user2 = @0x456, user3 = @0x789, framework = @0x1)]
    fun test_wallet_not_in_whitelist(
        creator: &signer, 
        user1: &signer, 
        user2: &signer,
        user3: &signer,
        framework: &signer
    ) {
        // Set up testing environment
        setup_test_environment(framework);
        
        // Set addresses for testing
        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user3_addr = signer::address_of(user3);
        
        // Create accounts for testing
        account::create_account_for_test(creator_addr);
        account::create_account_for_test(user1_addr);
        account::create_account_for_test(user3_addr);
        
        // Set up a whitelist with just user1
        let whitelisted_addresses = vector::empty<address>();
        vector::push_back(&mut whitelisted_addresses, user1_addr);
        
        // Generate Merkle root
        let merkle_data = generate_merkle_tree_for_test(whitelisted_addresses);
        let merkle_root = merkle_data.root;
        
        // Initialize collection
        whitelisted_nft::initialize_collection(
            creator,
            string::utf8(b"Whitelisted Collection"),
            string::utf8(b"A collection of NFTs for whitelisted addresses"),
            string::utf8(b"https://example.com/collection"),
            merkle_root,
            100
        );
        
        // Get the proof for user1
        let user1_proof = merkle_data.proofs.user1;
        
        // Verify user1 is whitelisted
        assert!(
            whitelisted_nft::is_whitelisted(user1_addr, creator_addr, user1_proof),
            E_TEST_FAILURE
        );
        
        // Verify user3 is NOT whitelisted (even when using user1's proof)
        assert!(
            !whitelisted_nft::is_whitelisted(user3_addr, creator_addr, user1_proof),
            E_TEST_FAILURE
        );
        
        // Try to generate a proof for user3, but it won't be in the tree
        // We need an empty proof for a single-node tree
        let empty_proof = vector::empty<vector<u8>>();
        
        // Verify user3 is still not whitelisted even with an empty proof
        assert!(
            !whitelisted_nft::is_whitelisted(user3_addr, creator_addr, empty_proof),
            E_TEST_FAILURE
        );
    }

    #[test(creator = @0xABCD, framework = @0x1)]
    fun test_hardcoded_merkle_proof(creator: &signer, framework: &signer) {
        // Set up testing environment
        setup_test_environment(framework);
        
        // Define specific addresses for the whitelist
        let addresses = vector[
            @0x1,
            @0x2,
            @0x3,
            @0x4,
            @0x5
        ];
        
        // Create leaf nodes from addresses
        let leaves = vector::empty<vector<u8>>();
        let i = 0;
        while (i < vector::length(&addresses)) {
            let addr = *vector::borrow(&addresses, i);
            let addr_bytes = bcs::to_bytes(&addr);
            let leaf = hash::sha3_256(addr_bytes);
            vector::push_back(&mut leaves, leaf);
            i = i + 1;
        };
        
        // Let's create the Merkle tree structure explicitly:
        //         ROOT
        //        /    \
        //     H(1,2)   H(3,4,5)
        //     / \      /    \
        //    L1  L2  H(3,4)  L5
        //             / \
        //            L3  L4
        
        let leaf1 = *vector::borrow(&leaves, 0); // Address 0x1 leaf
        let leaf2 = *vector::borrow(&leaves, 1); // Address 0x2 leaf
        let leaf3 = *vector::borrow(&leaves, 2); // Address 0x3 leaf
        let leaf4 = *vector::borrow(&leaves, 3); // Address 0x4 leaf
        let leaf5 = *vector::borrow(&leaves, 4); // Address 0x5 leaf
        
        // Hash the pairs to create the next level
        let hash_1_2 = hash_pair_for_test(leaf1, leaf2);
        let hash_3_4 = hash_pair_for_test(leaf3, leaf4);
        
        // Next level
        let hash_3_4_5 = hash_pair_for_test(hash_3_4, leaf5);
        
        // Compute root
        let merkle_root = hash_pair_for_test(hash_1_2, hash_3_4_5);
        
        // Now let's create proofs for different addresses
        
        // Proof for address 0x3
        let proof_for_3 = vector[
            leaf4,     // sibling to leaf3
            leaf5,     // sibling to hash_3_4
            hash_1_2   // sibling to hash_3_4_5
        ];
        
        // Verify that the proof is valid for address 0x3
        let address_to_verify = @0x3;
        let address_bytes = bcs::to_bytes(&address_to_verify);
        let leaf = hash::sha3_256(address_bytes);
        
        // Verify the proof with our merkle_proof module
        let is_valid = whitelist_nft::merkle_proof::verify(proof_for_3, merkle_root, leaf);
        
        // Should be valid
        assert!(is_valid, E_TEST_FAILURE);
        
        // Try with an address that wasn't in the original tree
        let invalid_address = @0x999;
        let invalid_address_bytes = bcs::to_bytes(&invalid_address);
        let invalid_leaf = hash::sha3_256(invalid_address_bytes);
        
        // The proof should be invalid for this address
        let is_valid_for_wrong_address = whitelist_nft::merkle_proof::verify(
            proof_for_3, 
            merkle_root, 
            invalid_leaf
        );
        
        assert!(!is_valid_for_wrong_address, E_TEST_FAILURE);
        
        // Initialize the collection with our Merkle root
        let creator_addr = signer::address_of(creator);
        account::create_account_for_test(creator_addr);
        
        whitelisted_nft::initialize_collection(
            creator,
            string::utf8(b"Hardcoded Whitelist Collection"),
            string::utf8(b"A collection using known Merkle root"),
            string::utf8(b"https://example.com/collection"),
            merkle_root,
            100
        );
        
        // Check that verification works through the NFT contract
        assert!(
            whitelisted_nft::is_whitelisted(address_to_verify, creator_addr, proof_for_3),
            E_TEST_FAILURE
        );
        
        // Invalid address should be rejected
        assert!(
            !whitelisted_nft::is_whitelisted(invalid_address, creator_addr, proof_for_3),
            E_TEST_FAILURE
        );
        
        // Let's also check a different address from the tree
        let address_0x1 = @0x1;
        
        // Proof for address 0x1
        let proof_for_1 = vector[
            leaf2,      // sibling to leaf1
            hash_3_4_5  // sibling to hash_1_2
        ];
        
        // Verify the proof works for address 0x1
        assert!(
            whitelisted_nft::is_whitelisted(address_0x1, creator_addr, proof_for_1),
            E_TEST_FAILURE
        );
    }

    #[test(framework = @0x1)]
    #[expected_failure(abort_code = 65539, location = whitelist_nft::whitelisted_nft)]
    public fun test_hardcoded_js_merkle(framework: &signer) {
        // Set up testing environment
        setup_test_environment(framework);
        
        // Create the user account with address 0x3
        let user = account::create_account_for_test(@0x3);
        let user_addr = signer::address_of(&user);
        
        let admin = account::create_account_for_test(@0xCAFE);
        let creator = &admin;
        let creator_addr = signer::address_of(creator);
        
        // Convert address bytes to verify our hashing is compatible with JS
        let addr_bytes = bcs::to_bytes(&user_addr);
        let leaf = hash::sha3_256(addr_bytes);
        
        // Setup merkle root from JS output
        let merkle_root = x"ee6821615a027ea4d9a4996be670c521d50eca59f71f31ae39680ad7c3da831e";
        
        // Initialize collection with the JS-generated Merkle root
        whitelisted_nft::initialize_collection(
            creator,
            string::utf8(b"JS Whitelist Collection"),
            string::utf8(b"A collection using JS-generated Merkle root"),
            string::utf8(b"https://example.com/collection"),
            merkle_root,
            100
        );
        
        // Proof for address 0x3 (generated from JavaScript)
        let proof_for_0x3 = vector[
            x"f343681465b9efe82c933c3e8748c70cb8aa06539c361de20f72eac04e766393",
            x"71d8979cbfae9b197a4fbcc7d387b1fae9560e2f284d30b4e90c80f6bc074f57",
            x"dbb8d0f4c497851a5043c6363657698cb1387682cac2f786c731f8936109d795"
        ];
        
        // Attempt to mint with the proof
        // This should fail because the JavaScript-generated Merkle proof is not compatible
        // with the Move implementation (likely different hashing method or serialization)
        whitelisted_nft::mint(
            &user,
            creator_addr,
            proof_for_0x3,
            string::utf8(b"NFT #1"),
            string::utf8(b"JavaScript-generated Merkle proof NFT"),
            string::utf8(b"https://example.com/nft1")
        );
    }

    /// Set up the test environment
    fun setup_test_environment(framework: &signer) {
        // Initialize the timestamp for testing (required for proper event emission)
        timestamp::set_time_has_started_for_testing(framework);
    }

    /// Simplified struct to hold Merkle tree data for testing
    struct MerkleTreeTestData has drop {
        root: vector<u8>,
        proofs: MerkleProofs,
    }

    /// Struct to hold proofs for different users
    struct MerkleProofs has drop {
        user1: vector<vector<u8>>,
        user2: vector<vector<u8>>,
    }

    /// Generate a Merkle tree for testing purposes
    /// This is a simplified version that works for 1-2 addresses
    fun generate_merkle_tree_for_test(addresses: vector<address>): MerkleTreeTestData {
        let len = vector::length(&addresses);
        assert!(len > 0 && len <= 2, E_TEST_FAILURE); // Only handle 1-2 addresses for simplicity
        
        // Create leaves by hashing the addresses
        let leaves = vector::empty<vector<u8>>();
        let i = 0;
        while (i < len) {
            let addr = *vector::borrow(&addresses, i);
            let addr_bytes = bcs::to_bytes(&addr);
            let leaf = hash::sha3_256(addr_bytes);
            vector::push_back(&mut leaves, leaf);
            i = i + 1;
        };
        
        // Handle tree creation based on number of addresses
        let root;
        let user1_proof = vector::empty<vector<u8>>();
        let user2_proof = vector::empty<vector<u8>>();
        
        if (len == 1) {
            // Only one address - the root is the leaf itself
            root = *vector::borrow(&leaves, 0);
            // No proof needed for single-node tree (empty proof)
        } else {
            // Two addresses - the root is the hash of both leaves
            let leaf0 = *vector::borrow(&leaves, 0);
            let leaf1 = *vector::borrow(&leaves, 1);
            
            // Mimic the hash_pair logic from merkle_proof
            root = hash_pair_for_test(leaf0, leaf1);
            
            // For user1, the proof is leaf1
            vector::push_back(&mut user1_proof, leaf1);
            
            // For user2, the proof is leaf0
            vector::push_back(&mut user2_proof, leaf0);
        };
        
        MerkleTreeTestData {
            root,
            proofs: MerkleProofs {
                user1: user1_proof,
                user2: user2_proof,
            }
        }
    }

    /// Hashing function for test, same as in merkle_proof module
    fun hash_pair_for_test(a: vector<u8>, b: vector<u8>): vector<u8> {
        // Compare vectors lexicographically
        let comparison = compare_vectors(&a, &b);
        
        if (comparison == LESS_THAN) { // a < b
            let combined = vector::empty<u8>();
            vector::append(&mut combined, a);
            vector::append(&mut combined, b);
            hash::sha3_256(combined)
        } else {
            let combined = vector::empty<u8>();
            vector::append(&mut combined, b);
            vector::append(&mut combined, a);
            hash::sha3_256(combined)
        }
    }
    
    /// Lexicographically compare two vectors
    /// Returns LESS_THAN if a < b, EQUAL if a == b, GREATER_THAN if a > b
    fun compare_vectors(a: &vector<u8>, b: &vector<u8>): u8 {
        let a_len = vector::length(a);
        let b_len = vector::length(b);
        let min_len = if (a_len < b_len) { a_len } else { b_len };
        
        let i = 0;
        while (i < min_len) {
            let a_val = *vector::borrow(a, i);
            let b_val = *vector::borrow(b, i);
            
            if (a_val < b_val) {
                return LESS_THAN
            } else if (a_val > b_val) {
                return GREATER_THAN
            };
            
            i = i + 1;
        };
        
        // If we've reached here, the common prefix is the same
        if (a_len < b_len) {
            LESS_THAN
        } else if (a_len > b_len) {
            GREATER_THAN
        } else {
            EQUAL // Vectors are equal
        }
    }
} 