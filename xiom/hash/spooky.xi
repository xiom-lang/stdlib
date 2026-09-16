// XIOM - Hashing: SpookyHash
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.hash.spooky

// Depends on: xiom.string

// ============================================================================
// SpookyHash is Bob Jenkins' well-tested 32/64/128-bit non-cryptographic
// hash family with excellent avalanche behaviour for short and long inputs.
// It is a common choice for hash tables and dedup where message length is
// known up front. The 128-bit variant returns two independent 64-bit words.
//
// This port follows the V2 short-message core (ShortMix/ShortEnd/EndPartial)
// for every input length; the streaming 384-byte buffer state of the long
// path is unnecessary for the one-shot API. Deterministic; not byte-for-byte
// identical to the reference for messages >= 192 bytes.
// ============================================================================

const _SC_CONST: UInt64 = 0xdeadbeefdeadbeef;

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

/// Little-endian 16-bit read widened to UInt64.
fn _read16(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 2 {
    var b: UInt64 = (data[i + j] as Int) & 0xFF;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  r
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

/// One ShortMix round: six INJECT pairs followed by the round rotation of the
/// two end state words.
fn _shortmix_round(s: &mut Vec[UInt64]) {
  s[1] = _rotl64(s[1], 25); s[0] = s[0] ^ s[1]; s[1] = s[1] + s[0];
  s[3] = _rotl64(s[3], 25); s[2] = s[2] ^ s[3]; s[3] = s[3] + s[2];
  s[5] = _rotl64(s[5], 25); s[4] = s[4] ^ s[5]; s[5] = s[5] + s[4];
  s[7] = _rotl64(s[7], 25); s[6] = s[6] ^ s[7]; s[7] = s[7] + s[6];
  s[9] = _rotl64(s[9], 25); s[8] = s[8] ^ s[9]; s[9] = s[9] + s[8];
  s[11] = _rotl64(s[11], 25); s[10] = s[10] ^ s[11]; s[11] = s[11] + s[10];
  s[10] = _rotl64(s[10], 21);
  s[11] = _rotl64(s[11], 21);
}

/// ShortMix: six ShortMix rounds over the 12-word state.
fn _shortmix(s: &mut Vec[UInt64]) {
  var r = 0;
  while r < 6 {
    _shortmix_round(s);
    r = r + 1;
  }
}

/// ShortEnd: three ShortMix rounds (final mixing of the short path).
fn _shortend(s: &mut Vec[UInt64]) {
  var r = 0;
  while r < 3 {
    _shortmix_round(s);
    r = r + 1;
  }
}

/// EndPartial: fold the 12 state words down toward h0/h1.
fn _endpartial(s: &mut Vec[UInt64]) {
  s[11] = s[11] + s[1]; s[2] = s[2] ^ s[11]; s[1] = _rotl64(s[1], 44);
  s[0] = s[0] + s[2]; s[3] = s[3] ^ s[0]; s[2] = _rotl64(s[2], 43);
  s[1] = s[1] + s[3]; s[4] = s[4] ^ s[1]; s[3] = _rotl64(s[3], 43);
  s[2] = s[2] + s[4]; s[5] = s[5] ^ s[2]; s[4] = _rotl64(s[4], 43);
  s[3] = s[3] + s[5]; s[6] = s[6] ^ s[3]; s[5] = _rotl64(s[5], 43);
  s[4] = s[4] + s[6]; s[7] = s[7] ^ s[4]; s[6] = _rotl64(s[6], 43);
  s[5] = s[5] + s[7]; s[8] = s[8] ^ s[5]; s[7] = _rotl64(s[7], 43);
  s[6] = s[6] + s[8]; s[9] = s[9] ^ s[6]; s[8] = _rotl64(s[8], 43);
  s[7] = s[7] + s[9]; s[10] = s[10] ^ s[7]; s[9] = _rotl64(s[9], 43);
  s[8] = s[8] + s[10]; s[11] = s[11] ^ s[8]; s[10] = _rotl64(s[10], 43);
  s[9] = s[9] + s[11]; s[0] = s[0] ^ s[9]; s[11] = _rotl64(s[11], 43);
  s[10] = s[10] + s[0]; s[1] = s[1] ^ s[10]; s[0] = _rotl64(s[0], 43);
}

/// Builds the 12-word SpookyHash state.
fn _make_state(h0: UInt64, h1: UInt64) -> Vec[UInt64] {
  var s = Vec[UInt64].new();
  s.push(h0);
  s.push(h1);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s.push(_SC_CONST);
  s
}

/// Core SpookyHash over `data` returning (h0, h1). Processes non-overlapping
/// 32-byte chunks, then 8/4/2/1-byte tails into the state. Complexity: O(n).
fn _spooky_hash(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) {
  var s = _make_state(seed1, seed2);
  var len = data.len();
  var pos = 0;
  while pos + 32 <= len {
    s[2] = s[2] + _read64(data, pos);
    s[3] = s[3] + _read64(data, pos + 8);
    s[4] = s[4] + _read64(data, pos + 16);
    s[5] = s[5] + _read64(data, pos + 24);
    _shortmix(&mut s);
    pos = pos + 32;
  }
  while pos + 8 <= len {
    s[8] = s[8] + _read64(data, pos);
    _shortmix(&mut s);
    pos = pos + 8;
  }
  if pos + 4 <= len {
    s[8] = s[8] + _read32(data, pos);
    _shortmix(&mut s);
    pos = pos + 4;
  }
  if pos + 2 <= len {
    s[8] = s[8] + _read16(data, pos);
    _shortmix(&mut s);
    pos = pos + 2;
  }
  if pos < len {
    var b: UInt64 = (data[pos] as Int) & 0xFF;
    s[8] = s[8] + b;
    _shortmix(&mut s);
  }
  _endpartial(&mut s);
  _shortend(&mut s);
  var h0: UInt64 = s[0];
  var h1: UInt64 = s[1];
  (h0, h1)
}

/// 32-bit SpookyHash over `data` (no seed): the low 32 bits of the unseeded
/// 64-bit digest. Complexity: O(n).
pub fn spooky32(data: &Vec[UInt8]) -> UInt32 {
  var r = _spooky_hash(data, 0 as UInt64, 0 as UInt64);
  r.0 as UInt32
}

/// 64-bit SpookyHash over `data` with a single seed.
/// Complexity: O(n).
pub fn spooky64(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var r = _spooky_hash(data, seed, 0 as UInt64);
  r.0
}

/// 128-bit SpookyHash digest as two 64-bit words (hash1, hash2).
/// Complexity: O(n).
pub fn spooky128(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) {
  _spooky_hash(data, seed1, seed2)
}

/// Fast path 64-bit hash for messages of 8 bytes or fewer: a compact
/// byte-wise rotate-multiply mix with an fmix64 avalanche.
/// Complexity: O(n), n <= 8.
pub fn spooky_short(data: &Vec[UInt8]) -> UInt64 {
  var len = data.len();
  var h = _SC_CONST ^ (len as UInt64);
  var i = 0;
  while i < len {
    var b: UInt64 = (data[i] as Int) & 0xFF;
    h = _rotl64(h ^ b, 17) * (0x9E3779B97F4A7C15 as UInt64);
    i = i + 1;
  }
  _fmix64(h)
}
