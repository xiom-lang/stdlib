// XIOM - Hashing: FarmHash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.farm

// Depends on: xiom.string

// ============================================================================
// FarmHash is Google's successor to CityHash, providing fast 32/64/128-bit
// non-cryptographic hashes with good distribution across platforms. It is
// ideal for hash maps, bloom filters, and fingerprinting strings and files.
//
// These are pure-XIOM FarmHash-style constructions: the HashLen16 fold with
// the k0/k1/k2 and kMul constants, ShiftMix avalanche, and 8-byte word
// mixing. Deterministic; not byte-for-byte identical to the reference.
// ============================================================================

const _K0: UInt64 = 0xc3a5c85c97cb3127;
const _K1: UInt64 = 0xb492b66fbe98f273;
const _K2: UInt64 = 0x9ae16a3b2f90404f;
const _KMUL: UInt64 = 0x9ddfea08eb382d69;

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

/// ShiftMix avalanche: val ^ (val >> 47).
fn _shiftmix(val: UInt64) -> UInt64 {
  val ^ _shr64(val, 47)
}

/// HashLen16: the FarmHash 16-byte fold.
fn _hashlen16(u: UInt64, v: UInt64) -> UInt64 {
  var a = (u ^ v) * _KMUL;
  a = a ^ _shr64(a, 47);
  var b = (v ^ a) * _KMUL;
  b = b ^ _shr64(b, 47);
  b * _KMUL
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

/// Shared 64-bit core: seed pair, 8-byte word mixing, tail fold.
fn _farm64_core(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> UInt64 {
  var len = data.len();
  var h = _hashlen16(seed1 ^ _K2, seed2 ^ _K1) ^ (len as UInt64);
  var pos = 0;
  while pos + 8 <= len {
    var w = _read64(data, pos);
    h = h ^ _shiftmix(w * _K0);
    h = _rotl64(h, 21) * _K1;
    pos = pos + 8;
  }
  var t = _read_tail(data, pos, len);
  _hashlen16(h, t ^ (len as UInt64))
}

/// FarmHash 64-bit digest over `data` (no seed). Complexity: O(n).
pub fn farmhash64(data: &Vec[UInt8]) -> UInt64 {
  _farm64_core(data, _K2, _K1)
}

/// FarmHash 64-bit digest with a single seed. Complexity: O(n).
pub fn farmhash64_seed(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  _farm64_core(data, seed, _K1)
}

/// FarmHash 64-bit digest with two seeds. Complexity: O(n).
pub fn farmhash64_seed2(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> UInt64 {
  _farm64_core(data, seed1, seed2)
}

/// FarmHash 32-bit digest over `data` (Murmur-style 4-byte mixing).
/// Complexity: O(n).
pub fn farmhash32(data: &Vec[UInt8]) -> UInt32 {
  var len = data.len();
  var h: UInt64 = (0x9E3779B9 as UInt64) ^ (len as UInt64);
  var pos = 0;
  while pos + 4 <= len {
    var w = _read32(data, pos);
    h = h ^ (w * _K0);
    h = _rotl64(h, 13) * (0x100000001B3 as UInt64);
    pos = pos + 4;
  }
  h = h ^ _read_tail(data, pos, len);
  h = _fmix64(h);
  h as UInt32
}

/// Shared 128-bit core: two lanes with alternating word mixing.
fn _farm128_core(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) {
  var len = data.len();
  var a: UInt64 = seed1 ^ _K0;
  var b: UInt64 = seed2 ^ _K1;
  var pos = 0;
  var toggle = 0;
  while pos + 8 <= len {
    var w = _read64(data, pos);
    if toggle == 0 {
      a = _rotl64(a ^ _shiftmix(w * _K0), 27) + b;
      a = a * _KMUL;
    } else {
      b = _rotl64(b ^ _shiftmix(w * _K1), 27) + a;
      b = b * _KMUL;
    };
    toggle = 1 - toggle;
    pos = pos + 8;
  }
  var t = _read_tail(data, pos, len);
  a = a ^ t;
  b = b ^ (len as UInt64);
  var lo: UInt64 = _hashlen16(a, b);
  var hi: UInt64 = _hashlen16(b ^ _rotl64(a, 33), _rotl64(a ^ b, 21));
  (lo, hi)
}

/// FarmHash 128-bit digest as two 64-bit words. Complexity: O(n).
pub fn farmhash128(data: &Vec[UInt8]) -> (UInt64, UInt64) {
  _farm128_core(data, _K0, _K1)
}

/// FarmHash 128-bit digest seeded with two 64-bit words.
/// Complexity: O(n).
pub fn farmhash128_seed(data: &Vec[UInt8], seed1: UInt64, seed2: UInt64) -> (UInt64, UInt64) {
  _farm128_core(data, seed1, seed2)
}

/// 32-bit fingerprint, stable across runs for the same data.
/// Complexity: O(n).
pub fn farmhash_fingerprint32(data: &Vec[UInt8]) -> UInt32 {
  farmhash32(data)
}

/// 64-bit fingerprint, stable across runs for the same data.
/// Complexity: O(n).
pub fn farmhash_fingerprint64(data: &Vec[UInt8]) -> UInt64 {
  farmhash64(data)
}

/// 128-bit fingerprint, stable across runs for the same data.
/// Complexity: O(n).
pub fn farmhash_fingerprint128(data: &Vec[UInt8]) -> (UInt64, UInt64) {
  farmhash128(data)
}
