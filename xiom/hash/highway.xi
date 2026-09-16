// XIOM - Hashing: HighwayHash
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.highway

// Depends on: xiom.string

// ============================================================================
// HighwayHash is a SIMD-friendly strong pseudo-random-function by Google that
// is very fast on modern CPUs while resisting many attacks on non-cryptographic
// hashes. It derives a 64/128/256-bit digest from four 64-bit keys. The pure
// XIOM port targets map/checksum use cases where xxHash-class speed and
// keyed output are both desirable.
//
// This is a pure-XIOM HighwayHash-style construction: four 64-bit lanes are
// seeded from the 256-bit key, 32-byte packets are folded into the lanes with
// rotate/multiply/XOR mixing, the tail is absorbed byte-wise, and the lanes
// are combined with an fmix64 avalanche. It is deterministic and keyed, but
// is NOT byte-for-byte identical to Google's reference output.
// ============================================================================

/// 128-bit HighwayHash digest: `low` is the low 64 bits, `high` the high.
pub type Hh128 = { low: UInt64; high: UInt64; }

/// Logical (unsigned) right shift of a UInt64 by k bits.
fn _shr64(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { var z: UInt64 = 0; return z; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  (x >> k) & mask
}

/// Rotate left a UInt64 by r bits.
fn _rotl64(x: UInt64, r: Int) -> UInt64 {
  var s = r % 64;
  if s == 0 { return x; }
  (x << s) | _shr64(x, 64 - s)
}

/// Little-endian 64-bit word read from the byte buffer.
fn _read64(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 8 {
    var b: UInt64 = (data[i + j] as Int) & 0xFF;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  r
}

/// Little-endian 32-bit read widened to UInt64.
fn _read32(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 4 {
    var b: UInt64 = (data[i + j] as Int) & 0xFF;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  r
}

/// fmix64 avalanche (MurmurHash3 finalizer).
fn _fmix64(k: UInt64) -> UInt64 {
  var x = k ^ _shr64(k, 33);
  x = x * (0xff51afd7ed558ccd as UInt64);
  x = x ^ _shr64(x, 33);
  x = x * (0xc4ceb9fe1a85ec53 as UInt64);
  x = x ^ _shr64(x, 33);
  x
}

/// Runs the HighwayHash-style core over `data` and returns the four final
/// lanes in a 4-element vector (v0, v1, v2, v3). Complexity: O(n).
fn _highway_core(data: &Vec[UInt8], k0: UInt64, k1: UInt64, k2: UInt64, k3: UInt64) -> Vec[UInt64] {
  var v0 = k0;
  var v1 = k1;
  var v2 = k2;
  var v3 = k3;
  var m0 = k0 ^ (0x243F6A8885A308D3 as UInt64);
  var m1 = k1 ^ (0x13198A2E03707344 as UInt64);
  var m2 = k2 ^ (0xA4093822299F31D0 as UInt64);
  var m3 = k3 ^ (0x082EFA98EC4E6C89 as UInt64);
  var len = data.len();
  var pos = 0;
  while pos + 32 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    var w2 = _read64(data, pos + 16);
    var w3 = _read64(data, pos + 24);
    v0 = _rotl64(v0 + w0, 32) ^ (m1 + w1);
    v1 = _rotl64(v1 + w1, 32) ^ (m2 + w2);
    v2 = _rotl64(v2 + w2, 32) ^ (m3 + w3);
    v3 = _rotl64(v3 + w3, 32) ^ (m0 + w0);
    v0 = _rotl64(v0 * m0, 27) + v1;
    v1 = _rotl64(v1 * m1, 27) + v2;
    v2 = _rotl64(v2 * m2, 27) + v3;
    v3 = _rotl64(v3 * m3, 27) + v0;
    var t0 = v0;
    v0 = v1;
    v1 = v2;
    v2 = v3;
    v3 = t0;
    pos = pos + 32;
  }
  while pos + 8 <= len {
    var w = _read64(data, pos);
    v0 = v0 ^ w;
    v0 = _rotl64(v0 * m1, 29) + w;
    pos = pos + 8;
  }
  if pos + 4 <= len {
    var w32 = _read32(data, pos);
    v1 = v1 ^ w32;
    v1 = _rotl64(v1 * m2, 31);
    pos = pos + 4;
  }
  while pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    v2 = _rotl64(v2 ^ b, 11) * m3;
    pos = pos + 1;
  }
  var lanes = Vec[UInt64].new();
  lanes.push(v0);
  lanes.push(v1);
  lanes.push(v2);
  lanes.push(v3);
  lanes
}

/// 64-bit HighwayHash over `data` with a 256-bit key.
/// Complexity: O(n).
pub fn highway64(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> UInt64 {
  var lanes = _highway_core(data, key0, key1, key2, key3);
  var h = lanes[0] ^ _rotl64(lanes[1], 17) ^ _rotl64(lanes[2], 33) ^ _rotl64(lanes[3], 49);
  h = h ^ (data.len() as UInt64);
  _fmix64(h)
}

/// 128-bit HighwayHash digest returned as a two-field struct (low, high).
/// Complexity: O(n).
pub fn highway128(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> Hh128 {
  var lanes = _highway_core(data, key0, key1, key2, key3);
  var l = _fmix64(lanes[0] ^ _rotl64(lanes[1], 25) ^ (data.len() as UInt64));
  var h = _fmix64(lanes[2] ^ _rotl64(lanes[3], 25) ^ _rotl64(data.len() as UInt64, 25));
  Hh128{ low: l; high: h; }
}

/// 256-bit HighwayHash digest as four 64-bit lanes (v0, v1, v2, v3).
/// Complexity: O(n).
pub fn highway256(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64) -> (UInt64, UInt64, UInt64, UInt64) {
  var lanes = _highway_core(data, key0, key1, key2, key3);
  var r0: UInt64 = _fmix64(lanes[0] ^ (data.len() as UInt64));
  var r1: UInt64 = _fmix64(lanes[1] ^ _rotl64(data.len() as UInt64, 17));
  var r2: UInt64 = _fmix64(lanes[2] ^ _rotl64(data.len() as UInt64, 33));
  var r3: UInt64 = _fmix64(lanes[3] ^ _rotl64(data.len() as UInt64, 49));
  (r0, r1, r2, r3)
}

/// 64-bit HighwayHash taking the four key words as a vector; traps if
/// key.len() != 4 (a programming error). Complexity: O(n).
pub fn highway_hash(data: &Vec[UInt8], key: Vec[UInt64]) -> UInt64
  requires: key.len() == 4
{
  highway64(data, key[0], key[1], key[2], key[3])
}

/// Rehashes `data` with the given key and compares against `expected`.
/// Complexity: O(n).
pub fn highway_verify(data: &Vec[UInt8], key0: UInt64, key1: UInt64, key2: UInt64, key3: UInt64, expected: UInt64) -> Bool {
  var h = highway64(data, key0, key1, key2, key3);
  h == expected
}
