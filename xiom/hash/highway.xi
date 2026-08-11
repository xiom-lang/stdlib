// XIOM - Hashing: HighwayHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.highway

// Depends on: xiom.string

// ============================================================================
// HighwayHash is a SIMD-friendly strong pseudo-random-function by Google that
// is very fast on modern CPUs while resisting many attacks on non-cryptographic
// hashes. It derives a 64/128/256-bit digest from four 64-bit keys. The pure
// XIOM port targets map/checksum use cases where xxHash-class speed and
// keyed output are both desirable.
// ============================================================================

// fn highway64(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> UInt64 - 64-bit HighwayHash over data with a 256-bit key. TODO(compiler): implement.
// fn highway128(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> Hh128 - 128-bit digest returned as a two-field struct (low: UInt64, high: UInt64) in the style of Xxh128. TODO(compiler): implement.
// fn highway256(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> (UInt64, UInt64, UInt64, UInt64) - 256-bit digest as four 64-bit lanes (mirrors the lane struct). TODO(compiler): implement.
// fn highway_hash(data: &Vec[UInt8], key: Vec[UInt64]) -> UInt64 - 64-bit HighwayHash taking the four key words as a vector; panics if key.len() != 4. TODO(compiler): implement.
// fn highway_verify(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64, expected: UInt64) -> Bool - rehashes data and compares against expected 64-bit digest. TODO(compiler): implement.
