module whitelist_nft::merkle_proof {
    use std::vector;
    use aptos_std::hash;

    /// Error codes
    const E_INVALID_PROOF: u64 = 1;
    const E_INVALID_LEAF: u64 = 2;

    // Constants for vector comparison results
    const LESS_THAN: u8 = 0;
    const EQUAL: u8 = 1;
    const GREATER_THAN: u8 = 2;

    /// Verifies that a leaf node is a member of a Merkle tree defined by
    /// a given root hash by computing the Merkle proof.
    /// 
    /// Arguments:
    /// * `proof` - The proof as a vector of sibling hashes from bottom to the top of the tree
    /// * `root` - The Merkle root hash
    /// * `leaf` - The leaf hash to verify membership for
    /// 
    /// Returns:
    /// * `true` if the proof is valid, `false` otherwise
    public fun verify(proof: vector<vector<u8>>, root: vector<u8>, leaf: vector<u8>): bool {
        let computed_hash = leaf;
        let i = 0;
        let len = vector::length(&proof);

        while (i < len) {
            let sibling = *vector::borrow(&proof, i);
            computed_hash = hash_pair(computed_hash, sibling);
            i = i + 1;
        };

        computed_hash == root
    }

    /// Hashes a pair of nodes in the Merkle tree
    /// Always sorts the nodes before hashing to maintain deterministic ordering
    fun hash_pair(a: vector<u8>, b: vector<u8>): vector<u8> {
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

    #[test]
    fun test_verify_proof() {
        // Simple test with a two-level Merkle tree
        //        root
        //       /    \
        //    hash01   hash23
        //    /   \     /   \
        //  hash0 hash1 hash2 hash3

        // Create some leaf values (simulating hashed addresses)
        let leaf0 = x"0000";
        let leaf1 = x"1111";
        let leaf2 = x"2222";
        let leaf3 = x"3333";

        // Hash the leaf pairs
        let hash01 = hash_pair(leaf0, leaf1);
        let hash23 = hash_pair(leaf2, leaf3);

        // Calculate the root
        let root = hash_pair(hash01, hash23);

        // Create proof for leaf0 (needs hash1, hash23)
        let proof0 = vector::empty<vector<u8>>();
        vector::push_back(&mut proof0, leaf1);
        vector::push_back(&mut proof0, hash23);

        // Verify proof for leaf0
        assert!(verify(proof0, root, leaf0), E_INVALID_PROOF);

        // Create proof for leaf2 (needs hash3, hash01)
        let proof2 = vector::empty<vector<u8>>();
        vector::push_back(&mut proof2, leaf3);
        vector::push_back(&mut proof2, hash01);

        // Verify proof for leaf2
        assert!(verify(proof2, root, leaf2), E_INVALID_PROOF);

        // Try with an invalid leaf - should return false
        assert!(!verify(proof0, root, leaf2), E_INVALID_LEAF);
    }
} 