// XIOM — Hashing: xxHash (XXH64 / XXH32)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.xxhash

// Faithful port of Yann Collet's xxHash (XXH64 and XXH32).
// All arithmetic is wrapping UInt64; the builtin `>>` on UInt64 is arithmetic
// (sign-filling), so every logical right shift goes through _u64_shr.

const PRIME64_1: UInt64 = 0x9E3779B185EBCA87;
const PRIME64_2: UInt64 = 0xC2B2AE3D27D4EB4F;
const PRIME64_3: UInt64 = 0x165667B19E3779F9;
const PRIME64_4: UInt64 = 0x85EBCA77C2B2AE63;
const PRIME64_5: UInt64 = 0x27D4EB2F165667C5;

const PRIME32_1: UInt64 = 0x9E3779B1;
const PRIME32_2: UInt64 = 0x85EBCA77;
const PRIME32_3: UInt64 = 0xC2B2AE3D;
const PRIME32_4: UInt64 = 0x27D4EB2F;
const PRIME32_5: UInt64 = 0x165667B1;

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

fn _rotl32(x: UInt64, r: Int) -> UInt64 {
  var s = r % 32;
  if s == 0 { return x; }
  return ((x << s) | _u64_shr(x, 32 - s)) & 0xFFFFFFFF;
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

fn _read32(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 4 {
    var b: UInt64 = data[i + j] as UInt64;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  return r & 0xFFFFFFFF;
}

fn _round64(acc: UInt64, lane: UInt64) -> UInt64 {
  var a = acc + lane * PRIME64_2;
  a = _rotl64(a, 31);
  a = a * PRIME64_1;
  return a;
}

fn _merge_round(acc: UInt64, val: UInt64) -> UInt64 {
  var v = val * PRIME64_1;
  v = _rotl64(v, 31);
  v = v * PRIME64_2;
  return acc ^ v;
}

fn _avalanche64(h: UInt64) -> UInt64 {
  var x = h ^ _u64_shr(h, 33);
  x = x * PRIME64_2;
  x = x ^ _u64_shr(x, 29);
  x = x * PRIME64_3;
  x = x ^ _u64_shr(x, 32);
  return x;
}

fn _round32(acc: UInt64, lane: UInt64) -> UInt64 {
  var k = (lane * PRIME32_2) & 0xFFFFFFFF;
  var a = (acc + k) & 0xFFFFFFFF;
  a = _rotl32(a, 13);
  a = (a * PRIME32_1) & 0xFFFFFFFF;
  return a;
}

/// XXH64 of a byte string with the given seed.
pub fn xxh64(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  let len = data.len();
  var p = 0;
  var h: UInt64 = 0;
  if len >= 32 {
    var v1 = seed + PRIME64_1 + PRIME64_2;
    var v2 = seed + PRIME64_2;
    var v3 = seed;
    var v4 = seed - PRIME64_1;
    while p + 32 <= len {
      v1 = _round64(v1, _read64(data, p));
      v2 = _round64(v2, _read64(data, p + 8));
      v3 = _round64(v3, _read64(data, p + 16));
      v4 = _round64(v4, _read64(data, p + 24));
      p = p + 32;
    }
    h = _rotl64(v1, 1) + _rotl64(v2, 7) + _rotl64(v3, 12) + _rotl64(v4, 18);
    h = _merge_round(h, v1);
    h = _merge_round(h, v2);
    h = _merge_round(h, v3);
    h = _merge_round(h, v4);
  } else {
    h = seed + PRIME64_5;
  }
  h = h + (len as UInt64);
  while p + 8 <= len {
    var k1 = _round64(0, _read64(data, p));
    h = h ^ k1;
    h = _rotl64(h, 27);
    h = h * PRIME64_1 + PRIME64_4;
    p = p + 8;
  }
  if p + 4 <= len {
    var w = _read32(data, p);
    h = h ^ (w * PRIME64_1);
    h = _rotl64(h, 23);
    h = h * PRIME64_2 + PRIME64_3;
    p = p + 4;
  }
  while p < len {
    var byte: UInt64 = data[p] as UInt64;
    h = h ^ (byte * PRIME64_5);
    h = _rotl64(h, 11);
    h = h * PRIME64_1;
    p = p + 1;
  }
  return _avalanche64(h);
}

/// XXH32 of a byte string with the given seed.
pub fn xxh32(data: &Vec[UInt8], seed: UInt32) -> UInt32 {
  let len = data.len();
  var s: UInt64 = seed as UInt64;
  var p = 0;
  var h: UInt64 = 0;
  if len >= 16 {
    var v1 = (s + PRIME32_1 + PRIME32_2) & 0xFFFFFFFF;
    var v2 = (s + PRIME32_2) & 0xFFFFFFFF;
    var v3 = s & 0xFFFFFFFF;
    var v4 = (s - PRIME32_1) & 0xFFFFFFFF;
    while p + 16 <= len {
      v1 = _round32(v1, _read32(data, p));
      v2 = _round32(v2, _read32(data, p + 4));
      v3 = _round32(v3, _read32(data, p + 8));
      v4 = _round32(v4, _read32(data, p + 12));
      p = p + 16;
    }
    h = (_rotl32(v1, 1) + _rotl32(v2, 7) + _rotl32(v3, 12) + _rotl32(v4, 18)) & 0xFFFFFFFF;
  } else {
    h = (s + PRIME32_5) & 0xFFFFFFFF;
  }
  h = (h + (len as UInt64)) & 0xFFFFFFFF;
  while p + 4 <= len {
    var k = (_read32(data, p) * PRIME32_3) & 0xFFFFFFFF;
    h = h ^ k;
    h = _rotl32(h, 17);
    h = (h * PRIME32_4) & 0xFFFFFFFF;
    p = p + 4;
  }
  while p < len {
    var byte: UInt64 = data[p] as UInt64;
    h = h ^ ((byte * PRIME32_5) & 0xFFFFFFFF);
    h = _rotl32(h, 11);
    h = (h * PRIME32_1) & 0xFFFFFFFF;
    p = p + 1;
  }
  h = h ^ _u64_shr(h, 15);
  h = (h * PRIME32_2) & 0xFFFFFFFF;
  h = h ^ _u64_shr(h, 13);
  h = (h * PRIME32_3) & 0xFFFFFFFF;
  h = h ^ _u64_shr(h, 16);
  return (h & 0xFFFFFFFF) as UInt32;
}
