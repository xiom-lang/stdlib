// XIOM - Hashing: SpookyHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.spooky

// ============================================================================
// SpookyHash is Bob Jenkins' well-tested 32/64/128-bit non-cryptographic
// hash family with excellent avalanche behaviour for short and long inputs.
// It is a common choice for hash tables and dedup where message length is
// known up front. The 128-bit variant returns two independent 64-bit words.
// ============================================================================

// fn spooky32(data: &Vec[UInt8]) -> UInt32 - 32-bit SpookyHash over data (no seed). TODO(compiler): implement.
// fn spooky64(data: &Vec[UInt8], seed: UInt64) -> UInt64 - 64-bit SpookyHash over data with a single seed. TODO(compiler): implement.
// fn spooky128(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) - 128-bit digest as two 64-bit words (hash1, hash2) via a small struct. TODO(compiler): implement.
// fn spooky_short(data: &Vec[UInt8]) -> UInt64 - fast path 64-bit hash for messages of 8 bytes or fewer. TODO(compiler): implement.
