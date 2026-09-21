// XIOM - Hashing: T1HA (Fast Positive Hash)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.t1ha

// Depends on: xiom.string

// ============================================================================
// T1HA is a family of fast non-cryptographic hashes from Positive Technologies
// that is among the fastest on modern x86-64 while keeping good distribution.
// t1ha0 is the latency-optimised portable variant; t1ha1 and t1ha2 trade a
// little speed for stronger avalanche across different message lengths.
//
// These are pure-XIOM t1ha-style constructions: word-oriented reads, per-lane
// rotate-multiply mixing with a length fold and fmix64 avalanche. Deterministic;
// not byte-for-byte identical to the reference implementations.
// ============================================================================

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
  x = x * 0xff51afd7ed558ccd;
  x = x ^ _shr64(x, 33);
  x = x * 0xc4ceb9fe1a85ec53;
  x = x ^ _shr64(x, 33);
  x
}

/// Reads the remaining tail bytes of `data` from `pos` into a zero-padded
/// little-endian word.
fn _read_tail(data: &Vec[UInt8], pos: Int, len: Int) -> UInt64 {
  var t: UInt64 = 0;
  var j = 0;
  while pos + j < len {
    var b: UInt64 = (data[pos + j] as Int) & 0xFF;
    t = t | (b << (8 * j));
    j = j + 1;
  }
  t
}

/// t1ha0 latency-optimised portable 64-bit hash: single lane, 8-byte word
/// mixing with a byte-wise tail fold. Complexity: O(n).
pub fn t1ha0(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  var h = seed ^ (0x100000001B3 as UInt64);
  var pos = 0;
  while pos + 8 <= len {
    var w = _read64(data, pos);
    h = _rotl64(h ^ w, 17) * (0x9E3779B97F4A7C15 as UInt64);
    h = h + _rotl64(w, 23);
    pos = pos + 8;
  }
  h = h ^ _read_tail(data, pos, len);
  h = h ^ (len as UInt64);
  _fmix64(h)
}

/// t1ha1 64-bit hash, well-tuned for medium inputs: two-lane 16-byte block
/// mixing. Complexity: O(n).
pub fn t1ha1(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  var a = seed;
  var b = seed ^ (0x9E3779B97F4A7C15 as UInt64);
  var pos = 0;
  while pos + 16 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    a = _rotl64(a ^ w0, 13) * (0x100000001B3 as UInt64);
    b = _rotl64(b ^ w1, 13) * (0x100000001B3 as UInt64);
    a = a + b;
    b = _rotl64(b, 31);
    pos = pos + 16;
  }
  var t = _read_tail(data, pos, len);
  a = a ^ t;
  a = _rotl64(a, 27) * (0xBF58476D1CE4E5B9 as UInt64);
  var h = a ^ _rotl64(b, 17) ^ (len as UInt64);
  _fmix64(h)
}

/// t1ha2 64-bit hash, strongest avalanche of the family: two lanes, 32-byte
/// block mixing with cross-lane addition. Complexity: O(n).
pub fn t1ha2(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var r = _t1ha2_core(data, seed);
  r.0
}

/// t1ha2 one-shot 64-bit hash with implicit zero seed. Complexity: O(n).
pub fn t1ha2_atonce(data: &Vec[UInt8]) -> UInt64 {
  var r = _t1ha2_core(data, 0 as UInt64);
  r.0
}

/// t1ha2 one-shot 128-bit digest as two 64-bit words. Complexity: O(n).
pub fn t1ha2_atonce128(data: &Vec[UInt8]) -> (UInt64, UInt64) {
  var r = _t1ha2_core(data, 0 as UInt64);
  r
}

/// Two-lane t1ha2 core returning (r0, r1).
fn _t1ha2_core(data: &Vec[UInt8], seed: UInt64) -> (UInt64, UInt64) {
  var len = data.len();
  var a = seed;
  var b = seed ^ (0x243F6A8885A308D3 as UInt64);
  var pos = 0;
  while pos + 32 <= len {
    var w0 = _read64(data, pos);
    var w1 = _read64(data, pos + 8);
    var w2 = _read64(data, pos + 16);
    var w3 = _read64(data, pos + 24);
    a = a ^ w0 ^ w1;
    b = b ^ w2 ^ w3;
    a = _rotl64(a, 29) * (0xBF58476D1CE4E5B9 as UInt64);
    b = _rotl64(b, 29) * (0x94D049BB133111EB as UInt64);
    a = a + b;
    b = b ^ a;
    pos = pos + 32;
  }
  a = a ^ _read_tail(data, pos, len);
  a = a ^ (len as UInt64);
  b = b ^ _rotl64(len as UInt64, 27);
  var r0: UInt64 = _fmix64(a ^ _rotl64(b, 27));
  var r1: UInt64 = _fmix64(b ^ _rotl64(a, 27));
  (r0, r1)
}

/// t1ha variant tuned for IA-32 targets: smaller state, 4-byte word mixing.
/// Complexity: O(n).
pub fn t1ha_ia32(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  var h = seed ^ (0xA5A5A5A5A5A5A5A5 as UInt64);
  var pos = 0;
  while pos + 4 <= len {
    var w = _read32(data, pos);
    h = _rotl64(h ^ w, 13) * (0x100000001B3 as UInt64);
    pos = pos + 4;
  }
  h = h ^ _read_tail(data, pos, len);
  h = h ^ (len as UInt64);
  _fmix64(h)
}
