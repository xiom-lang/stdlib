// XIOM - Hashing: FNV (Fowler-Noll-Vo)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.fnv

// Depends on: xiom.string

// ============================================================================
// FNV-1 and FNV-1a are simple non-cryptographic hashes based on a prime
// multiplication per byte. 32/64-bit variants already exist in hash.xi;
// this module adds the 128-bit variants used for larger keys and ID
// generation where collision resistance beyond 64 bits is required.
// ============================================================================

// fn fnv1_128(data: &Vec[UInt8]) -> UInt128 - FNV-1 128-bit hash over data. TODO(compiler): implement.
// fn fnv1a_128(data: &Vec[UInt8]) -> UInt128 - FNV-1a 128-bit hash over data (xor first, then multiply). TODO(compiler): implement.
// fn fnv1a_128_seed(data: &Vec[UInt8], seed: UInt128) -> UInt128 - FNV-1a 128-bit hash starting from an explicit seed. TODO(compiler): implement.
