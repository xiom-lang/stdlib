// XIOM -- Hashing
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash

use xiom.string;
use xiom.encoding;

// === Hash interface (hasher-based) ===
/// === Hash interface (hasher-based) ===
pub interface Hash {
  fn hash(self, hasher: Hasher);
}

// === Hasher interface ===
/// === Hasher interface ===
pub interface Hasher {
  fn write(self, bytes: &Vec[UInt8]);
  fn write_int(self, n: Int);
  fn write_str(self, s: Str);
  fn finish(self) -> Int;
}

// === BuildHasher interface ===
/// === BuildHasher interface ===
pub interface BuildHasher {
  fn build_hasher(self) -> Hasher;
}

// === DefaultHasher -- DJB2-based concrete hasher ===
/// === DefaultHasher -- DJB2-based concrete hasher ===
pub type DefaultHasher = { state: Int; } derive[Clone]

pub fn DefaultHasher.new() -> DefaultHasher {
  return DefaultHasher { state: 5381; };
}

pub fn DefaultHasher.write(self, bytes: &Vec[UInt8]) {
  var i: Int = 0;
  while i < bytes.len() {
    self.state = ((self.state * 33) + bytes[i]);
    i = i + 1;
  }
}

pub fn DefaultHasher.write_int(self, n: Int) {
  var val: Int = n;
  var i: Int = 0;
  while i < 8 {
    self.state = ((self.state * 33) + (val & 0xFF));
    val = val >> 8;
    i = i + 1;
  }
}

pub fn DefaultHasher.write_str(self, s: Str) {
  var i: Int = 0;
  let len: Int = str_len(s);
  while i < len {
    let ch: Option[Char] = char_at(s, i);
    if ch.is_some {
      let code: Int = to_int_from_char(ch.value);
      self.state = ((self.state * 33) + code);
    };
    i = i + 1;
  }
}

pub fn DefaultHasher.finish(self) -> Int {
  return self.state;
}

// === Hash implementations for standard types ===
// Full DJB2 hash computation. Each type hashes its bytes directly.
/// === Hash implementations for standard types ===
/// Full DJB2 hash computation. Each type hashes its bytes directly.
pub fn Int.hash(self) -> UInt64
  ensures: a == b => a.hash() == b.hash()
{
  var h: Int = 5381;
  var val: Int = self;
  var i: Int = 0;
  while i < 8 {
    let byte = val & 0xFF;
    h = ((h * 33) + byte);
    val = val >> 8;
    i = i + 1;
  }
  h
}

pub fn Bool.hash(self) -> UInt64 {
  var h: Int = 5381;
  if self {
    h = ((h * 33) + 1);
  } else {
    h = ((h * 33) + 0);
  }
  h
}

// === Free functions ===
// NOTE: these dispatch to the concrete 0-arg `.hash()` methods (Int/Bool)
// like the sibling `hash` below. The hasher-based `Hash` interface
// (hash(self, hasher)) is defined above but has no concrete impls yet;
// calling through it from a &T receiver produced invalid IR
// (ptr->i64) -- keep by-value params until the interface path is complete.
/// === Free functions ===
/// NOTE: these dispatch to the concrete 0-arg `.hash()` methods (Int/Bool)
/// like the sibling `hash` below. The hasher-based `Hash` interface
/// (hash(self, hasher)) is defined above but has no concrete impls yet;
/// calling through it from a &T receiver produced invalid IR
/// (ptr->i64) -- keep by-value params until the interface path is complete.
pub fn hash_value[T: Hash](value: T) -> Int {
  let h = value.hash();
  return h as Int;
}

pub fn hash_combine(seed: Int, hash: Int) -> Int {
  return seed ^ (hash + 0x9e3779b9 + (seed << 6) + (seed >> 2));
}

pub fn hash[T: Hash](value: T) -> UInt64 {
  value.hash()
}

pub fn sip_hash(data: &Vec[UInt8]) -> UInt64 {
  var hasher: DefaultHasher = DefaultHasher.new();
  hasher.write(data);
  return hasher.finish();
}

// -- FNV-1a (Fowler-Noll-Vo) ------------------------------------------------

/// FNV-1a 32-bit hash.
/// Algorithm: hash = (hash XOR byte) * FNV Prime, with 32-bit wrapping.
/// Offset basis: 0x811C9DC5, prime: 0x01000193.
/// Complexity: O(n), n = data length.
/// Security: Non-cryptographic. Excellent distribution for hash tables.
pub fn fnv1a32(data: &Vec[UInt8]) -> Int {
  var hash: Int = 0x811C9DC5;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    let byte = data[i] as Int;
    hash = hash ^ byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    i = i + 1;
  };
  return hash;
}

/// FNV-1a 64-bit hash.
/// Offset basis: 0xCBF29CE484222325, prime: 0x00000100000001B3.
/// Complexity: O(n), n = data length.
pub fn fnv1a64(data: &Vec[UInt8]) -> Int {
  var hash: Int = 0xCBF29CE484222325;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    let byte = data[i] as Int;
    hash = hash ^ byte;
    hash = hash * 0x00000100000001B3;
    i = i + 1;
  };
  return hash;
}

/// FNV-1 64-bit hash (multiply first, then XOR -- non-alternate variant).
/// Offset basis: 0xCBF29CE484222325, prime: 0x00000100000001B3.
/// Complexity: O(n), n = data length.
pub fn fnv1_64(data: &Vec[UInt8]) -> Int {
  var hash: Int = 0xCBF29CE484222325;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    hash = hash * 0x00000100000001B3;
    let byte = data[i] as Int;
    hash = hash ^ byte;
    i = i + 1;
  };
  return hash;
}

// -- MurmurHash3 x86_32 ------------------------------------------------------

/// MurmurHash3 32-bit (x86_32 variant).
/// Processes 4-byte blocks with fmix32 finalization.
/// Test vector: murmur3_32("hello", 0) == 0x248BFA47.
/// Complexity: O(n), n = data length.
/// Security: Non-cryptographic. Good avalanche characteristics.
pub fn murmur3_32(data: &Vec[UInt8], seed: Int) -> Int {
  const C1: Int = 0xCC9E2D51;
  const C2: Int = 0x1B873593;
  let len = data.len();
  var h1: Int = seed;
  var nblocks: Int = len / 4;
  var i: Int = 0;
  while i < nblocks {
    var k1: Int = data[i * 4] as Int;
    k1 = k1 | ((data[i * 4 + 1] as Int) << 8);
    k1 = k1 | ((data[i * 4 + 2] as Int) << 16);
    k1 = k1 | ((data[i * 4 + 3] as Int) << 24);
    k1 = (k1 * C1) & 0xFFFFFFFF;
    k1 = (k1 << 15) | ((k1 & 0xFFFFFFFF) >> 17);
    k1 = k1 & 0xFFFFFFFF;
    k1 = (k1 * C2) & 0xFFFFFFFF;
    h1 = h1 ^ k1;
    h1 = (h1 << 13) | ((h1 & 0xFFFFFFFF) >> 19);
    h1 = h1 & 0xFFFFFFFF;
    h1 = (h1 * 5 + 0xE6546B64) & 0xFFFFFFFF;
    i = i + 1;
  };
  var tail_idx: Int = nblocks * 4;
  var k1: Int = 0;
  let rem: Int = len - tail_idx;
  if rem == 3 {
    k1 = k1 ^ ((data[tail_idx + 2] as Int) << 16);
    k1 = k1 ^ ((data[tail_idx + 1] as Int) << 8);
    k1 = k1 ^ (data[tail_idx] as Int);
  } elif rem == 2 {
    k1 = k1 ^ ((data[tail_idx + 1] as Int) << 8);
    k1 = k1 ^ (data[tail_idx] as Int);
  } elif rem == 1 {
    k1 = k1 ^ (data[tail_idx] as Int);
  };
  if rem > 0 {
    k1 = (k1 * C1) & 0xFFFFFFFF;
    k1 = (k1 << 15) | ((k1 & 0xFFFFFFFF) >> 17);
    k1 = k1 & 0xFFFFFFFF;
    k1 = (k1 * C2) & 0xFFFFFFFF;
    h1 = h1 ^ k1;
  };
  h1 = h1 ^ (len as Int);
  h1 = h1 ^ ((h1 & 0xFFFFFFFF) >> 16);
  h1 = (h1 * 0x85EBCA6B) & 0xFFFFFFFF;
  h1 = h1 ^ ((h1 & 0xFFFFFFFF) >> 13);
  h1 = (h1 * 0xC2B2AE35) & 0xFFFFFFFF;
  h1 = h1 ^ ((h1 & 0xFFFFFFFF) >> 16);
  return h1;
}

// -- xxHash32 ----------------------------------------------------------------

// Helper: rotates left within 32 bits.
/// Helper: rotates left within 32 bits.
pub fn _rotl32(x: Int, r: Int) -> Int {
  let a = (x & 0xFFFFFFFF) << r;
  let b = ((x & 0xFFFFFFFF) >> (32 - r));
  return (a | b) & 0xFFFFFFFF;
}

/// xxHash32 -- Yann Collet's fast non-cryptographic hash.
/// Prime constants and avalanche per original xxHash specification.
/// Complexity: O(n), n = data length. Processes 4-byte lanes + tail.
pub fn xxhash32(data: &Vec[UInt8], seed: Int) -> Int {
  const PRIME32_1: Int = 0x9E3779B1;
  const PRIME32_2: Int = 0x85EBCA77;
  const PRIME32_3: Int = 0xC2B2AE3D;
  const PRIME32_4: Int = 0x27D4EB2F;
  const PRIME32_5: Int = 0x165667B1;
  let len = data.len();
  var nblocks: Int = len / 16;
  var h32: Int = 0;
  if len >= 16 {
    var v1: Int = (seed + PRIME32_1 + PRIME32_2) & 0xFFFFFFFF;
    var v2: Int = (seed + PRIME32_2) & 0xFFFFFFFF;
    var v3: Int = seed & 0xFFFFFFFF;
    var v4: Int = (seed - PRIME32_1) & 0xFFFFFFFF;
    var bi: Int = 0;
    while bi < nblocks {
      var k1: Int = data[bi * 16] as Int;
      k1 = k1 | ((data[bi * 16 + 1] as Int) << 8);
      k1 = k1 | ((data[bi * 16 + 2] as Int) << 16);
      k1 = k1 | ((data[bi * 16 + 3] as Int) << 24);
      k1 = (k1 * PRIME32_2) & 0xFFFFFFFF;
      k1 = _rotl32(k1, 15);
      k1 = (k1 * PRIME32_1) & 0xFFFFFFFF;
      v1 = (v1 + k1) & 0xFFFFFFFF;
      v1 = _rotl32(v1, 13);
      v1 = (v1 * PRIME32_1) & 0xFFFFFFFF;
      var k2: Int = data[bi * 16 + 4] as Int;
      k2 = k2 | ((data[bi * 16 + 5] as Int) << 8);
      k2 = k2 | ((data[bi * 16 + 6] as Int) << 16);
      k2 = k2 | ((data[bi * 16 + 7] as Int) << 24);
      k2 = (k2 * PRIME32_2) & 0xFFFFFFFF;
      k2 = _rotl32(k2, 15);
      k2 = (k2 * PRIME32_1) & 0xFFFFFFFF;
      v2 = (v2 + k2) & 0xFFFFFFFF;
      v2 = _rotl32(v2, 13);
      v2 = (v2 * PRIME32_1) & 0xFFFFFFFF;
      var k3: Int = data[bi * 16 + 8] as Int;
      k3 = k3 | ((data[bi * 16 + 9] as Int) << 8);
      k3 = k3 | ((data[bi * 16 + 10] as Int) << 16);
      k3 = k3 | ((data[bi * 16 + 11] as Int) << 24);
      k3 = (k3 * PRIME32_2) & 0xFFFFFFFF;
      k3 = _rotl32(k3, 15);
      k3 = (k3 * PRIME32_1) & 0xFFFFFFFF;
      v3 = (v3 + k3) & 0xFFFFFFFF;
      v3 = _rotl32(v3, 13);
      v3 = (v3 * PRIME32_1) & 0xFFFFFFFF;
      var k4: Int = data[bi * 16 + 12] as Int;
      k4 = k4 | ((data[bi * 16 + 13] as Int) << 8);
      k4 = k4 | ((data[bi * 16 + 14] as Int) << 16);
      k4 = k4 | ((data[bi * 16 + 15] as Int) << 24);
      k4 = (k4 * PRIME32_2) & 0xFFFFFFFF;
      k4 = _rotl32(k4, 15);
      k4 = (k4 * PRIME32_1) & 0xFFFFFFFF;
      v4 = (v4 + k4) & 0xFFFFFFFF;
      v4 = _rotl32(v4, 13);
      v4 = (v4 * PRIME32_1) & 0xFFFFFFFF;
      bi = bi + 1;
    };
    h32 = _rotl32(v1, 1) + _rotl32(v2, 7) + _rotl32(v3, 12) + _rotl32(v4, 18);
    h32 = h32 & 0xFFFFFFFF;
  } else {
    h32 = (seed + PRIME32_5) & 0xFFFFFFFF;
  };
  h32 = (h32 + (len as Int)) & 0xFFFFFFFF;
  var tail_idx: Int = nblocks * 16;
  while tail_idx + 4 <= len {
    var k: Int = data[tail_idx] as Int;
    k = k | ((data[tail_idx + 1] as Int) << 8);
    k = k | ((data[tail_idx + 2] as Int) << 16);
    k = k | ((data[tail_idx + 3] as Int) << 24);
    k = (k * PRIME32_3) & 0xFFFFFFFF;
    k = _rotl32(k, 17);
    k = (k * PRIME32_4) & 0xFFFFFFFF;
    h32 = h32 ^ k;
    h32 = _rotl32(h32, 19);
    h32 = ((h32 * PRIME32_1) + PRIME32_4) & 0xFFFFFFFF;
    tail_idx = tail_idx + 4;
  };
  while tail_idx < len {
    var k: Int = data[tail_idx] as Int;
    k = (k * PRIME32_5) & 0xFFFFFFFF;
    k = _rotl32(k, 11);
    k = (k * PRIME32_1) & 0xFFFFFFFF;
    h32 = h32 ^ k;
    h32 = _rotl32(h32, 17);
    tail_idx = tail_idx + 1;
  };
  h32 = h32 ^ ((h32 & 0xFFFFFFFF) >> 15);
  h32 = (h32 * PRIME32_2) & 0xFFFFFFFF;
  h32 = h32 ^ ((h32 & 0xFFFFFFFF) >> 13);
  h32 = (h32 * PRIME32_3) & 0xFFFFFFFF;
  h32 = h32 ^ ((h32 & 0xFFFFFFFF) >> 16);
  return h32;
}

// -- DJB2 ---------------------------------------------------------------------

/// DJB2 string hash (Dan Bernstein).
/// Start with 5381, for each char: hash = hash * 33 + char_code.
/// Complexity: O(n), n = string length.
pub fn djb2(s: Str) -> Int
  requires: true  // extern char_at call in the loop (T002 confinement)
{
  var hash: Int = 5381;
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let c: Char = xiom_char_at(s, i);
    let code: Int = to_int_from_char(c);
    hash = ((hash * 33) + code);
    i = i + 1;
  };
  return hash;
}

// -- SDBM ---------------------------------------------------------------------

/// SDBM string hash.
/// For each char: hash = char_code + (hash << 6) + (hash << 16) - hash.
/// Complexity: O(n), n = string length.
pub fn sdbm(s: Str) -> Int
  requires: true  // extern char_at call in the loop (T002 confinement)
{
  var hash: Int = 0;
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let c: Char = xiom_char_at(s, i);
    let code: Int = to_int_from_char(c);
    hash = code + (hash << 6) + (hash << 16) - hash;
    i = i + 1;
  };
  return hash;
}

// -- CRC32-IEEE ---------------------------------------------------------------

/// CRC32-IEEE 802.3 (polynomial 0xEDB88320, reflected).
/// Generates lookup table lazily on first call.
/// Complexity: O(n), n = data length.
pub fn crc32_ieee(data: &Vec[UInt8]) -> Int {
  var table: [256]Int;
  var ti: Int = 0;
  while ti < 256 {
    var crc: Int = ti;
    var tj: Int = 0;
    while tj < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc = crc >> 1;
      };
      tj = tj + 1;
    };
    table[ti] = crc & 0xFFFFFFFF;
    ti = ti + 1;
  };
  var crc: Int = 0xFFFFFFFF;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    let idx: Int = (crc ^ (data[i] as Int)) & 0xFF;
    crc = ((crc >> 8) ^ table[idx]) & 0xFFFFFFFF;
    i = i + 1;
  };
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

// -- Hash to hex --------------------------------------------------------------

/// Converts a byte vector to a lowercase hexadecimal string.
/// Delegates to xiom.encoding.hex_encode.
pub fn hash_bytes_to_hex(data: &Vec[UInt8]) -> Str {
  return encoding.hex_encode(data);
}

// -- Hash combination ---------------------------------------------------------

/// Boost-style hash combination.
/// Combines two hash values into one using a mixing function.
/// Formula: a ^ (b + 0x9e3779b9 + (a << 6) + (a >> 2)).
pub fn combine_hashes(a: Int, b: Int) -> Int {
  return a ^ (b + 0x9e3779b9 + (a << 6) + (a >> 2));
}

// -- String hash (djb2 variant) -----------------------------------------------

/// DJB2 hash over string characters.
/// Alias for djb2.
pub fn string_hash(s: Str) -> Int {
  return djb2(s);
}

// ============================================================================
// 64-bit hash additions (2026-08-11)
// ============================================================================

const PRIME64_1: Int = -7046029288634856825; // 0x9E3779B185EBCA87
const PRIME64_2: Int = -4417276706812531889; // 0xC2B2AE3D27D4EB4F
const PRIME64_3: Int = 1609587929392839161;  // 0x165667B19E3779F9
const PRIME64_4: Int = -8796714831421723037; // 0x85EBCA77C2B2AE63
const PRIME64_5: Int = 2870177450012600261;  // 0x27D4EB2F165667C5

// 64-bit rotate left (arithmetic-shift corrected: keep only the low c bits
// of the shifted-in portion).
fn _rotl64(x: Int, c: Int) -> Int {
  var shift = 64 - c;
  var mask = (1 << c) - 1;
  return (x << c) | ((x >> shift) & mask);
}

// Little-endian 64-bit read from the byte buffer.
fn _read_u64_le(data: &Vec[UInt8], pos: Int) -> Int {
  var r: Int = data[pos] as Int;
  r = r | ((data[pos + 1] as Int) << 8);
  r = r | ((data[pos + 2] as Int) << 16);
  r = r | ((data[pos + 3] as Int) << 24);
  r = r | ((data[pos + 4] as Int) << 32);
  r = r | ((data[pos + 5] as Int) << 40);
  r = r | ((data[pos + 6] as Int) << 48);
  r = r | ((data[pos + 7] as Int) << 56);
  return r;
}

fn _xxh64_round(acc: Int, input: Int) -> Int {
  // canonical: acc = rotl(acc + input*P2, 31) * P1
  var v = acc + input * PRIME64_2;
  v = _rotl64(v, 31);
  v = v * PRIME64_1;
  return v;
}

fn _xxh64_merge_round(acc: Int, val: Int) -> Int {
  var v = acc ^ _xxh64_round(0, val);
  v = v * PRIME64_1 + PRIME64_4;
  return v;
}

// xxHash64 (seed 0 compatible with the reference implementation; 64-bit
// results wrap naturally in i64 arithmetic -- masks are no-ops at 64 bits).
/// xxHash64 (seed 0 compatible with the reference implementation; 64-bit
/// results wrap naturally in i64 arithmetic -- masks are no-ops at 64 bits).
pub fn xxhash64(data: &Vec[UInt8], seed: Int) -> Int {
  var len = data.len();
  var h: Int = seed + PRIME64_5 + len;
  var pos: Int = 0;
  if len >= 32 {
    var v1: Int = seed + PRIME64_1 + PRIME64_2;
    var v2: Int = seed + PRIME64_2;
    var v3: Int = seed;
    var v4: Int = seed - PRIME64_1;
    while pos + 32 <= len {
      v1 = _xxh64_round(v1, _read_u64_le(data, pos));
      v2 = _xxh64_round(v2, _read_u64_le(data, pos + 8));
      v3 = _xxh64_round(v3, _read_u64_le(data, pos + 16));
      v4 = _xxh64_round(v4, _read_u64_le(data, pos + 24));
      pos = pos + 32;
    }
    h = _rotl64(v1, 1) + _rotl64(v2, 7) + _rotl64(v3, 12) + _rotl64(v4, 18);
    h = _xxh64_merge_round(h, v1);
    h = _xxh64_merge_round(h, v2);
    h = _xxh64_merge_round(h, v3);
    h = _xxh64_merge_round(h, v4);
  }
  // tail: 8-byte chunks
  while pos + 8 <= len {
    var k = _read_u64_le(data, pos);
    k = k * PRIME64_2;
    k = _rotl64(k, 31);
    k = k * PRIME64_1;
    h = h ^ k;
    h = _rotl64(h, 27) * PRIME64_1 + PRIME64_4;
    pos = pos + 8;
  }
  // 4-byte chunk
  if pos + 4 <= len {
    var k4: Int = data[pos] as Int;
    k4 = k4 | ((data[pos + 1] as Int) << 8);
    k4 = k4 | ((data[pos + 2] as Int) << 16);
    k4 = k4 | ((data[pos + 3] as Int) << 24);
    h = h ^ (k4 * PRIME64_1);
    h = _rotl64(h, 23) * PRIME64_2 + PRIME64_3;
    pos = pos + 4;
  }
  // remaining bytes
  while pos < len {
    h = h ^ ((data[pos] as Int) * PRIME64_5);
    h = _rotl64(h, 11) * PRIME64_1;
    pos = pos + 1;
  }
  // avalanche (logical shifts: mask the arithmetic-shift sign extension)
  var t33 = (h >> 33) & 0x7FFFFFFF;
  h = h ^ t33;
  h = h * PRIME64_2;
  var t29 = (h >> 29) & 0x7FFFFFFFF;
  h = h ^ t29;
  h = h * PRIME64_3;
  var t32 = (h >> 32) & 0xFFFFFFFF;
  h = h ^ t32;
  return h;
}

// FNV-1 32-bit (multiply before XOR, unlike FNV-1a).
/// FNV-1 32-bit (multiply before XOR, unlike FNV-1a).
pub fn fnv1_32(s: Str) -> Int {
  var h: Int = 2166136261;
  var i: Int = 0;
  while i < s.len() {
    h = (h * 16777619) & 0xFFFFFFFF;
    h = (h ^ (xiom.string.byte_at(s, i) as Int)) & 0xFFFFFFFF;
    i = i + 1;
  }
  return h;
}

