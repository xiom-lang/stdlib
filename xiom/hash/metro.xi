// XIOM - Hashing: MetroHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.metro

// ============================================================================
// MetroHash is a fast non-cryptographic hash by J. Andrew Rogers designed
// around hardware multiply and 64-bit word reads. Its 64/128-bit variants
// target hash tables and file checksums where throughput matters more than
// cryptographic strength.
// ============================================================================

// fn metrohash64(data: &Vec[UInt8], seed: UInt64) -> UInt64 - MetroHash64 v1 64-bit digest over data. TODO(compiler): implement.
// fn metrohash64_2(data: &Vec[UInt8], seed: UInt64) -> UInt64 - MetroHash64 v2 64-bit digest (fixed-width, seedable). TODO(compiler): implement.
// fn metrohash128(data: &Vec[UInt8], seed: UInt64) -> (UInt64, UInt64) - MetroHash128 128-bit digest as two 64-bit words. TODO(compiler): implement.
// fn metrohash128crc(data: &Vec[UInt8], seed: UInt64) -> (UInt64, UInt64) - MetroHash128 with CRC32 hardware acceleration when available (pure fallback). TODO(compiler): implement.
// fn metrohash32(data: &Vec[UInt8], seed: UInt32) -> UInt32 - MetroHash32 compact 32-bit digest for small tables. TODO(compiler): implement.
