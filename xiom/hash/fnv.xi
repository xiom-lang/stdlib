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

const _FNV128_OFFSET: UInt128 = 0x6C62272E07BB014262B821756295C58D as UInt128;
const _FNV128_PRIME: UInt128 = 0x0000000001000000000000000000013B as UInt128;
const _FNV64_OFFSET: UInt64 = 0xCBF29CE484222325 as UInt64;
const _FNV64_PRIME: UInt64 = 0x00000100000001B3 as UInt64;

/// FNV-1 128-bit hash: multiply first, then XOR each byte.
/// Offset basis 0x6C62272E07BB014262B821756295C58D, prime 2^24 + 2^8 + 0x3B.
/// Empty input yields the offset basis. Complexity: O(n).
pub fn fnv1_128(data: &Vec[UInt8]) -> UInt128 {
  var hash: UInt128 = _FNV128_OFFSET;
  var i = 0;
  var len = data.len();
  while i < len {
    hash = hash * _FNV128_PRIME;
    var b = (data[i] as Int) & 0xFF;
    hash = hash ^ (b as UInt128);
    i = i + 1;
  };
  hash
}

/// FNV-1a 128-bit hash: XOR first, then multiply each byte.
/// Empty input yields the offset basis. Complexity: O(n).
pub fn fnv1a_128(data: &Vec[UInt8]) -> UInt128 {
  var hash: UInt128 = _FNV128_OFFSET;
  var i = 0;
  var len = data.len();
  while i < len {
    var b = (data[i] as Int) & 0xFF;
    hash = hash ^ (b as UInt128);
    hash = hash * _FNV128_PRIME;
    i = i + 1;
  };
  hash
}

/// FNV-1a 128-bit hash starting from an explicit seed. The seed replaces the
/// offset basis; a zero-length input yields the seed unchanged.
/// Complexity: O(n).
pub fn fnv1a_128_seed(data: &Vec[UInt8], seed: UInt128) -> UInt128 {
  var hash: UInt128 = seed;
  var i = 0;
  var len = data.len();
  while i < len {
    var b = (data[i] as Int) & 0xFF;
    hash = hash ^ (b as UInt128);
    hash = hash * _FNV128_PRIME;
    i = i + 1;
  };
  hash
}

/// FNV-1a 64-bit hash (completeness companion to the 128-bit variants in this
/// module). Offset basis 0xCBF29CE484222325, prime 0x100000001B3. Empty input
/// yields the offset basis. Complexity: O(n).
pub fn fnv1a64(data: &Vec[UInt8]) -> UInt64 {
  var hash: UInt64 = _FNV64_OFFSET;
  var i = 0;
  var len = data.len();
  while i < len {
    var b = (data[i] as Int) & 0xFF;
    hash = hash ^ (b as UInt64);
    hash = hash * _FNV64_PRIME;
    i = i + 1;
  };
  hash
}
