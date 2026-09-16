// XIOM -- Hashing: MurmurHash (MurmurHash3 x64_128 / MurmurHash64A)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.murmur

// Faithful ports of MurmurHash3_x64_128 and MurmurHash64A (Austin Appleby).
// All arithmetic is wrapping UInt64; the builtin `>>` on UInt64 is arithmetic
// (sign-filling), so every logical right shift goes through _u64_shr.

const _C1: UInt64 = 0x87c37b91114253d5;
const _C2: UInt64 = 0x4cf5ad432745937f;
const _M64A: UInt64 = 0xc6a4a7935bd1e995;

/// Logical (unsigned) right shift of a UInt64 by k bits.
fn _u64_shr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { var z: UInt64 = 0; return z; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

fn _rotl64(x: UInt64, r: Int) -> UInt64 {
  var s = r % 64;
  if s == 0 { return x; }
  return (x << s) | _u64_shr(x, 64 - s);
}

fn _read64(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 8 {
    var b: UInt64 = data[i + j] as UInt64;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  return r;
}

fn _fmix64(k: UInt64) -> UInt64 {
  var x = k ^ _u64_shr(k, 33);
  x = x * 0xff51afd7ed558ccd;
  x = x ^ _u64_shr(x, 33);
  x = x * 0xc4ceb9fe1a85ec53;
  x = x ^ _u64_shr(x, 33);
  return x;
}

/// MurmurHash3 x64_128 of a byte string; returns [h1, h2].
pub fn murmur3_128(data: &Vec[UInt8], seed: UInt32) -> Vec[UInt64] {
  let len = data.len();
  var h1: UInt64 = seed as UInt64;
  var h2: UInt64 = seed as UInt64;
  var nblocks = len / 16;
  var p = 0;
  while p < nblocks * 16 {
    var k1 = _read64(data, p);
    var k2 = _read64(data, p + 8);
    k1 = k1 * _C1;
    k1 = _rotl64(k1, 31);
    k1 = k1 * _C2;
    h1 = h1 ^ k1;
    h1 = _rotl64(h1, 27);
    h1 = h1 + h2;
    h1 = h1 * 5 + 0x52dce729;
    k2 = k2 * _C2;
    k2 = _rotl64(k2, 33);
    k2 = k2 * _C1;
    h2 = h2 ^ k2;
    h2 = _rotl64(h2, 31);
    h2 = h2 + h1;
    h2 = h2 * 5 + 0x38495ab5;
    p = p + 16;
  }
  var tail = nblocks * 16;
  var k1: UInt64 = 0;
  var k2: UInt64 = 0;
  var rem = len - tail;
  if rem > 8 {
    k1 = _read64(data, tail);
    var idx = tail + 8;
    var shift = 0;
    while idx < len {
      var b: UInt64 = data[idx] as UInt64;
      k2 = k2 ^ (b << shift);
      idx = idx + 1;
      shift = shift + 8;
    }
  } elif rem > 0 {
    var idx = tail;
    var shift = 0;
    while idx < len {
      var b: UInt64 = data[idx] as UInt64;
      k1 = k1 ^ (b << shift);
      idx = idx + 1;
      shift = shift + 8;
    }
  }
  if rem > 8 {
    k2 = k2 * _C2;
    k2 = _rotl64(k2, 33);
    k2 = k2 * _C1;
    h2 = h2 ^ k2;
  }
  if rem > 0 {
    k1 = k1 * _C1;
    k1 = _rotl64(k1, 31);
    k1 = k1 * _C2;
    h1 = h1 ^ k1;
  }
  h1 = h1 ^ (len as UInt64);
  h2 = h2 ^ (len as UInt64);
  h1 = h1 + h2;
  h2 = h2 + h1;
  h1 = _fmix64(h1);
  h2 = _fmix64(h2);
  h1 = h1 + h2;
  h2 = h2 + h1;
  var out = Vec[UInt64].new();
  out.push(h1);
  out.push(h2);
  return out;
}

/// MurmurHash64A of a byte string with the given seed.
pub fn murmur2_64(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var r = 47;
  let len = data.len();
  var h = seed ^ ((len as UInt64) * _M64A);
  var p = 0;
  while p + 8 <= len {
    var k = _read64(data, p);
    k = k * _M64A;
    k = k ^ _u64_shr(k, r);
    k = k * _M64A;
    h = h ^ k;
    h = h * _M64A;
    p = p + 8;
  }
  var rem = len - p;
  if rem >= 7 { h = h ^ ((data[p + 6] as UInt64) << 48); }
  if rem >= 6 { h = h ^ ((data[p + 5] as UInt64) << 40); }
  if rem >= 5 { h = h ^ ((data[p + 4] as UInt64) << 32); }
  if rem >= 4 { h = h ^ ((data[p + 3] as UInt64) << 24); }
  if rem >= 3 { h = h ^ ((data[p + 2] as UInt64) << 16); }
  if rem >= 2 { h = h ^ ((data[p + 1] as UInt64) << 8); }
  if rem >= 1 {
    h = h ^ (data[p] as UInt64);
    h = h * _M64A;
  }
  h = h ^ _u64_shr(h, r);
  h = h * _M64A;
  h = h ^ _u64_shr(h, r);
  return h;
}
