// XIOM - Hashing: MetroHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.metro

// Depends on: xiom.string

// ============================================================================
// MetroHash is a fast non-cryptographic hash by J. Andrew Rogers designed
// around hardware multiply and 64-bit word reads. Its 64/128-bit variants
// target hash tables and file checksums where throughput matters more than
// cryptographic strength.
//
// These are pure-XIOM ports of the published MetroHash64 v1 structure
// (k0..k3 constants, 32-byte block lanes, tail and avalanche steps). MetroHash
// v2 and the 128-bit variants follow the same lane construction with their own
// folds. Deterministic; not byte-for-byte identical to the reference.
// ============================================================================

const _K0: UInt64 = 0xD6D018F5;
const _K1: UInt64 = 0xA2AA033B;
const _K2: UInt64 = 0x62992FC1;
const _K3: UInt64 = 0x30BC5B29;

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

/// Rotate right a UInt64 by r bits.
fn _rotr64(x: UInt64, r: Int) -> UInt64 {
  var s = r % 64;
  if s == 0 { return x; }
  _shr64(x, s) | (x << (64 - s))
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

/// The four-lane 32-byte block fold of MetroHash64 v1 (returns 4 lanes).
fn _metro_round(v0: UInt64, v1: UInt64, v2: UInt64, v3: UInt64) -> Vec[UInt64] {
  var a0 = _rotr64(v0, 29) + v2;
  var a1 = _rotr64(v1, 29) + v3;
  var a2 = _rotr64(v2, 29) + a0;
  var a3 = _rotr64(v3, 29) + a1;
  a0 = _rotr64(a0, 29) + a2;
  a1 = _rotr64(a1, 29) + a3;
  a2 = _rotr64(a2, 29) + a0;
  a3 = _rotr64(a3, 29) + a1;
  a0 = _rotr64(a0, 29) + a2;
  a1 = _rotr64(a1, 29) + a3;
  a2 = _rotr64(a2, 29) + a0;
  a3 = _rotr64(a3, 29) + a1;
  a0 = _rotr64(a0, 29) + a2;
  a1 = _rotr64(a1, 29) + a3;
  a2 = _rotr64(a2, 29) + a0;
  a3 = _rotr64(a3, 29) + a1;
  var out = Vec[UInt64].new();
  out.push(a0);
  out.push(a1);
  out.push(a2);
  out.push(a3);
  out
}

/// MetroHash64 v1 64-bit digest over `data`. Complexity: O(n).
pub fn metrohash64(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  var h = (seed + _K2) * _K0;
  var pos = 0;
  while pos + 32 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    var w2 = _read64(data, pos + 16);
    var w3 = _read64(data, pos + 24);
    var v0 = (w0 - _K0) * _K3;
    var v1 = (w1 - _K1) * _K2;
    var v2 = (w2 - _K0) * _K3;
    var v3 = (w3 - _K1) * _K2;
    var lanes = _metro_round(v0, v1, v2, v3);
    h = h ^ lanes[0] ^ lanes[1] ^ lanes[2] ^ lanes[3];
    h = h * _K0 + _K1;
    pos = pos + 32;
  }
  if pos + 16 <= len {
    var v0 = h + (_read64(data, pos) * _K0);
    var v1 = h + (_read64(data, pos + 8) * _K1);
    v0 = _rotr64(v0, 29) + v1;
    v1 = _rotr64(v1, 29) + v0;
    v0 = _rotr64(v0, 29) + v1;
    h = h ^ v0;
    h = _rotl64(h, 13) * _K0 + _K2;
    pos = pos + 16;
  }
  if pos + 8 <= len {
    h = h + _read64(data, pos) * _K0;
    h = _rotr64(h, 23) * _K1 + _K3;
    pos = pos + 8;
  }
  if pos + 4 <= len {
    h = h ^ (_read32(data, pos) * _K0);
    h = _rotr64(h, 11) * _K1 + _K2;
    pos = pos + 4;
  }
  while pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    h = h ^ (b * _K0);
    h = _rotr64(h, 11) * _K1;
    pos = pos + 1;
  }
  h = h ^ _shr64(h, 33);
  h = h * _K0;
  h = h ^ _shr64(h, 29);
  h = h * _K1;
  h = h ^ _shr64(h, 32);
  h
}

/// MetroHash64 v2 64-bit digest (fixed-width, seedable). Uses the same lane
/// construction as v1 with a length-aware final fold. Complexity: O(n).
pub fn metrohash64_2(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  var h = (seed + _K2) * _K0;
  var pos = 0;
  while pos + 32 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    var w2 = _read64(data, pos + 16);
    var w3 = _read64(data, pos + 24);
    var v0 = (w0 - _K0) * _K3;
    var v1 = (w1 - _K1) * _K2;
    var v2 = (w2 - _K0) * _K3;
    var v3 = (w3 - _K1) * _K2;
    var lanes = _metro_round(v0, v1, v2, v3);
    h = h ^ lanes[0] ^ lanes[1] ^ lanes[2] ^ lanes[3];
    h = h * _K0 + _K1;
    pos = pos + 32;
  }
  if pos + 16 <= len {
    var v0 = h + (_read64(data, pos) * _K1);
    var v1 = h + (_read64(data, pos + 8) * _K0);
    v0 = _rotl64(v0, 33) + v1;
    v1 = _rotl64(v1, 33) + v0;
    v0 = _rotl64(v0, 33) + v1;
    h = h ^ v0;
    h = h * _K0 + _K2;
    pos = pos + 16;
  }
  while pos + 8 <= len {
    h = h + _read64(data, pos) * _K1;
    h = _rotr64(h, 21) * _K0 + _K3;
    pos = pos + 8;
  }
  while pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    h = h ^ (b * _K2);
    h = _rotr64(h, 13) * _K3;
    pos = pos + 1;
  }
  h = h ^ (len as UInt64);
  h = h ^ _shr64(h, 33);
  h = h * _K1;
  h = h ^ _shr64(h, 29);
  h = h * _K0;
  h = h ^ _shr64(h, 32);
  h
}

/// MetroHash128 128-bit digest as two 64-bit words (low, high).
/// Complexity: O(n).
pub fn metrohash128(data: &Vec[UInt8], seed: UInt64) -> (UInt64, UInt64) {
  var len = data.len();
  var h1: UInt64 = (seed + _K2) * _K0;
  var h2: UInt64 = (seed + _K3) * _K1;
  var pos = 0;
  while pos + 32 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    var w2 = _read64(data, pos + 16);
    var w3 = _read64(data, pos + 24);
    var v0 = (w0 - _K0) * _K3;
    var v1 = (w1 - _K1) * _K2;
    var v2 = (w2 - _K0) * _K3;
    var v3 = (w3 - _K1) * _K2;
    var lanes = _metro_round(v0, v1, v2, v3);
    h1 = h1 ^ lanes[0] ^ lanes[1];
    h2 = h2 ^ lanes[2] ^ lanes[3];
    h1 = h1 * _K0 + _K1;
    h2 = h2 * _K1 + _K0;
    pos = pos + 32;
  }
  if pos + 16 <= len {
    var v0 = h1 + (_read64(data, pos) * _K0);
    var v1 = h2 + (_read64(data, pos + 8) * _K1);
    v0 = _rotr64(v0, 29) + v1;
    v1 = _rotr64(v1, 29) + v0;
    v0 = _rotr64(v0, 29) + v1;
    h1 = h1 ^ v0;
    h2 = h2 ^ _rotl64(v1, 17);
    pos = pos + 16;
  }
  while pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    h1 = h1 ^ (b * _K0);
    h1 = _rotr64(h1, 11) * _K1;
    h2 = h2 ^ (b * _K1);
    h2 = _rotr64(h2, 11) * _K0;
    pos = pos + 1;
  }
  h1 = h1 ^ (len as UInt64);
  h2 = h2 ^ (len as UInt64);
  h1 = _fmix64(h1);
  h2 = _fmix64(h2);
  (h1, h2)
}

/// MetroHash128 with CRC32 hardware acceleration when available. This pure
/// fallback is identical to metrohash128 (no CRC32 instruction dependency).
/// Complexity: O(n).
pub fn metrohash128crc(data: &Vec[UInt8], seed: UInt64) -> (UInt64, UInt64) {
  metrohash128(data, seed)
}

/// MetroHash32 compact 32-bit digest for small tables: 4-byte word mixing
/// with a 32-bit fold. Complexity: O(n).
pub fn metrohash32(data: &Vec[UInt8], seed: UInt32) -> UInt32 {
  var len = data.len();
  var h: UInt64 = (seed as UInt64) ^ (0x9E3779B9 as UInt64);
  var pos = 0;
  while pos + 4 <= len {
    var w = _read32(data, pos);
    h = h ^ (w * _K0);
    h = _rotr64(h, 17) * _K1;
    pos = pos + 4;
  }
  var t: UInt64 = 0;
  var j = 0;
  while pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    t = t | (b << (8 * j));
    j = j + 1;
    pos = pos + 1;
  }
  h = h ^ t;
  h = h ^ (len as UInt64);
  h = _fmix64(h);
  h as UInt32
}

/// fmix64 avalanche (MurmurHash3 finalizer).
fn _fmix64(k: UInt64) -> UInt64 {
  var x = k ^ _shr64(k, 33);
  x = x * 0xff51afd7ed558ccd;
  x = x ^ _shr64(x, 33);
  x = x * 0xc4ceb9fe1a85ec53;
  x = x ^ _shr64(x, 33);
  x
}
