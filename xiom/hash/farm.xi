// XIOM - Hashing: FarmHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.farm

// ============================================================================
// FarmHash is Google's successor to CityHash, providing fast 32/64/128-bit
// non-cryptographic hashes with good distribution across platforms. It is
// ideal for hash maps, bloom filters, and fingerprinting strings and files.
// ============================================================================

// fn farmhash32(data: &Vec[UInt8]) -> UInt32 - FarmHash 32-bit digest over data. TODO(compiler): implement.
// fn farmhash64(data: &Vec[UInt8]) -> UInt64 - FarmHash 64-bit digest over data (no seed). TODO(compiler): implement.
// fn farmhash64_seed(data: &Vec[UInt8], seed: UInt64) -> UInt64 - FarmHash 64-bit digest with a single seed. TODO(compiler): implement.
// fn farmhash64_seed2(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> UInt64 - FarmHash 64-bit digest with two seeds. TODO(compiler): implement.
// fn farmhash128(data: &Vec[UInt8]) -> (UInt64, UInt64) - FarmHash 128-bit digest as two 64-bit words. TODO(compiler): implement.
// fn farmhash128_seed(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) - FarmHash 128-bit digest seeded with two 64-bit words. TODO(compiler): implement.
// fn farmhash_fingerprint32(data: &Vec[UInt8]) -> UInt32 - 32-bit fingerprint, stable across runs for the same data. TODO(compiler): implement.
// fn farmhash_fingerprint64(data: &Vec[UInt8]) -> UInt64 - 64-bit fingerprint, stable across runs for the same data. TODO(compiler): implement.
// fn farmhash_fingerprint128(data: &Vec[UInt8]) -> (UInt64, UInt64) - 128-bit fingerprint, stable across runs for the same data. TODO(compiler): implement.
