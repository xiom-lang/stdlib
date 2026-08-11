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

// ============================================================================
// XXH3 — 64-bit and 128-bit (2026-08-11)
// ============================================================================
// Faithful port of the official XXH3 (xxHash v0.8.3, scalar path) with seed
// support. Verified against a clang-built reference (official xxhash.h
// v0.8.3): seed-0 vectors for "", "a", "abc", "message digest", the classic
// fox sentence and an 80-byte input, plus XXH3_64bits_withSeed("abc", 42).
// All secret byte reads go through _secret64_at (the seeded secret is
// kSecret with +seed on even lanes, -seed on odd lanes — the v0.8.3
// initCustomSecret_scalar rule; several paths read the secret at unaligned
// byte offsets (3, 11, 17, 103, 119, 121), so a byte-addressed reader is
// required for exactness). Pure XIOM; UInt64 wrapping via LLVM i64 ops.

const _P32_1: UInt64 = 0x9E3779B1;
const _P32_2: UInt64 = 0x85EBCA77;
const _P32_3: UInt64 = 0xC2B2AE3D;
const _P64_1: UInt64 = 0x9E3779B185EBCA87;
const _P64_2: UInt64 = 0xC2B2AE3D27D4EB4F;
const _P64_3: UInt64 = 0x165667B19E3779F9;
const _P64_4: UInt64 = 0x85EBCA77C2B2AE63;
const _P64_5: UInt64 = 0x27D4EB2F165667C5;
const _MX1: UInt64 = 0x165667919E3779F9;
const _MX2: UInt64 = 0x9FB21C651E98DF25;

// Default secret, 192 bytes read as 24 little-endian u64 lanes (kSecret,
// xxHash v0.8.3).
fn _ksecret(i: Int) -> UInt64 {
  if i == 0 { return 0xbe4ba423396cfeb8; }
  if i == 1 { return 0x1cad21f72c81017c; }
  if i == 2 { return 0xdb979083e96dd4de; }
  if i == 3 { return 0x1f67b3b7a4a44072; }
  if i == 4 { return 0x78e5c0cc4ee679cb; }
  if i == 5 { return 0x2172ffcc7dd05a82; }
  if i == 6 { return 0x8e2443f7744608b8; }
  if i == 7 { return 0x4c263a81e69035e0; }
  if i == 8 { return 0xcb00c391bb52283c; }
  if i == 9 { return 0xa32e531b8b65d088; }
  if i == 10 { return 0x4ef90da297486471; }
  if i == 11 { return 0xd8acdea946ef1938; }
  if i == 12 { return 0x3f349ce33f76faa8; }
  if i == 13 { return 0x1d4f0bc7c7bbdcf9; }
  if i == 14 { return 0x3159b4cd4be0518a; }
  if i == 15 { return 0x647378d9c97e9fc8; }
  if i == 16 { return 0xc3ebd33483acc5ea; }
  if i == 17 { return 0xeb6313faffa081c5; }
  if i == 18 { return 0x49daf0b751dd0d17; }
  if i == 19 { return 0x9e68d429265516d3; }
  if i == 20 { return 0xfca1477d58be162b; }
  if i == 21 { return 0xce31d07ad1b8f88f; }
  if i == 22 { return 0x280416958f3acb45; }
  return 0x7e404bbbcaafb7d7;
}

// Seeded secret lane: even lanes +seed, odd lanes -seed (v0.8.3 scalar).
fn _secret64(lane: Int, seed: UInt64) -> UInt64 {
  var v = _ksecret(lane);
  if (lane & 1) == 0 {
    return v + seed;
  }
  return v - seed;
}

// Byte i of the seeded secret (0..191).
fn _secret_byte(i: Int, seed: UInt64) -> UInt64 {
  var lane = i >> 3;
  var off = i & 7;
  var v = _secret64(lane, seed);
  return (v >> (off * 8)) & 0xFF;
}

// Unaligned 8-byte LE read of the seeded secret at byte offset off.
fn _secret64_at(off: Int, seed: UInt64) -> UInt64 {
  var r: UInt64 = 0;
  var k: Int = 0;
  while k < 8 {
    r = r | (_secret_byte(off + k, seed) << (k * 8));
    k = k + 1;
  }
  return r;
}

// Unaligned 4-byte LE read of the seeded secret at byte offset off.
fn _secret32_at(off: Int, seed: UInt64) -> UInt64 {
  return _secret64_at(off, seed) & 0xFFFFFFFF;
}

// Logical (unsigned) right shift.
// NOTE: two-var body — a single-var `var mask = ...; return ... & mask;`
// body is mis-inlined by the compiler (the mask statement is dropped,
// COMPILER_BUGS.md BUG 15). Keep the two-var form.
fn _shr(x: UInt64, k: Int) -> UInt64 {
  var shift = 64 - k;
  var mask: UInt64 = ((1 as UInt64) << shift) - 1;
  return (x >> k) & mask;
}

fn _rotl(x: UInt64, c: Int) -> UInt64 {
  return (x << c) | _shr(x, 64 - c);
}

// 32-bit rotate (for values held in a UInt64 — the 64-bit rotate does not
// wrap the top bits back into the low positions). NOTE: the shared _rotl32
// at the top of this file (xxh32 section) serves this role; a duplicate
// definition was removed (STDLIB_AUDIT.md anomaly 2).


fn _swap64(x: UInt64) -> UInt64 {
  return ((x & 0xFF) << 56) | ((x & 0xFF00) << 40) | ((x & 0xFF0000) << 24)
       | ((x & 0xFF000000) << 8) | ((x & 0xFF00000000) >> 8)
       | ((x & 0xFF0000000000) >> 24) | ((x & 0xFF000000000000) >> 40)
       | (_shr(x, 56) & 0xFF);
}

fn _swap32(x: UInt64) -> UInt64 {
  return ((x & 0xFF) << 24) | ((x & 0xFF00) << 8) | ((x & 0xFF0000) >> 8)
       | ((x & 0xFF000000) >> 24);
}

fn _read64(data: &Vec[UInt8], pos: Int) -> UInt64 {
  var r: UInt64 = data[pos] as UInt64;
  r = r | ((data[pos + 1] as UInt64) << 8);
  r = r | ((data[pos + 2] as UInt64) << 16);
  r = r | ((data[pos + 3] as UInt64) << 24);
  r = r | ((data[pos + 4] as UInt64) << 32);
  r = r | ((data[pos + 5] as UInt64) << 40);
  r = r | ((data[pos + 6] as UInt64) << 48);
  r = r | ((data[pos + 7] as UInt64) << 56);
  return r;
}

fn _read32(data: &Vec[UInt8], pos: Int) -> UInt64 {
  var r: UInt64 = data[pos] as UInt64;
  r = r | ((data[pos + 1] as UInt64) << 8);
  r = r | ((data[pos + 2] as UInt64) << 16);
  r = r | ((data[pos + 3] as UInt64) << 24);
  return r;
}

// Named pair (UInt64 tuples collide with Int tuples in catalog codegen).
type U64Pair = { lo: UInt64; hi: UInt64; }

// UInt64 → UInt128: the compiler emits SEXT for `v as UInt128` (bit 63
// sign-extends — COMPILER_BUGS.md BUG 14). Build from 32-bit halves, whose
// sext == zext since bit 63 is clear.
fn _u64_to_u128(v: UInt64) -> UInt128 {
  var lo32 = v & 0xFFFFFFFF;
  var hi32 = (v >> 32) & 0xFFFFFFFF;
  var r: UInt128 = lo32 as UInt128;
  r = r | ((hi32 as UInt128) << 32);
  return r;
}

// 64x64 -> 128 product (native LLVM i128). The high half masks the `>>`
// (UInt128 arithmetic shift sign-extends bit 127 — COMPILER_BUGS.md BUG 14).
fn _mult64to128(lhs: UInt64, rhs: UInt64) -> U64Pair {
  var p: UInt128 = _u64_to_u128(lhs) * _u64_to_u128(rhs);
  var lo = (p & (0xFFFFFFFFFFFFFFFF as UInt128)) as UInt64;
  var hi_mask: UInt128 = ((1 as UInt128) << 64) - 1;
  var hi = ((p >> 64) & hi_mask) as UInt64;
  return U64Pair{ lo: lo; hi: hi; };
}

fn _mul128_fold64(lhs: UInt64, rhs: UInt64) -> UInt64 {
  var p = _mult64to128(lhs, rhs);
  return p.lo ^ p.hi;
}

// 32x32 -> 64 multiply (no overflow: fits in 64 bits).
fn _mult32to64(lhs: UInt64, rhs: UInt64) -> UInt64 {
  return (lhs & 0xFFFFFFFF) * (rhs & 0xFFFFFFFF);
}

fn _xorshift(v: UInt64, s: Int) -> UInt64 {
  return v ^ _shr(v, s);
}

fn _avalanche64(h: UInt64) -> UInt64 {
  var v = _xorshift(h, 33);
  v = v * _P64_2;
  v = _xorshift(v, 29);
  v = v * _P64_3;
  return _xorshift(v, 32);
}

fn _avalanche3(h: UInt64) -> UInt64 {
  var v = _xorshift(h, 37);
  v = v * _MX1;
  return _xorshift(v, 32);
}

fn _rrmxmx(h: UInt64, len: UInt64) -> UInt64 {
  var v = h ^ _rotl(h, 49) ^ _rotl(h, 24);
  v = v * _MX2;
  v = v ^ (_shr(v, 35) + len);
  v = v * _MX2;
  return _xorshift(v, 28);
}

// mix16B: the short paths use kSecret bytes with +seed/-seed applied in the
// formula; only the long path feeds the seeded custom secret (via the
// _scalar_round2/_scramble/_mix2accs family, which pass seed into
// _secret64_at directly).
fn _mix16b_at(data: &Vec[UInt8], pos: Int, off: Int, seed: UInt64) -> UInt64 {
  var lo = _read64(data, pos) ^ (_secret64_at(off, 0) + seed);
  var hi = _read64(data, pos + 8) ^ (_secret64_at(off + 8, 0) - seed);
  return _mul128_fold64(lo, hi);
}

// ---- 64-bit short inputs ----

fn _len_1to3_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  var c1: UInt64 = data[0] as UInt64;
  var c2: UInt64 = data[len >> 1] as UInt64;
  var c3: UInt64 = data[len - 1] as UInt64;
  var combined: UInt64 = (c1 << 16) | (c2 << 24) | c3 | ((len as UInt64) << 8);
  var bitflip = (_secret32_at(0, 0) ^ _secret32_at(4, 0)) + seed;
  return _avalanche64(combined ^ bitflip);
}

fn _len_4to8_64(data: &Vec[UInt8], len: Int, seed_in: UInt64) -> UInt64 {
  var seed = seed_in ^ (_swap32(seed_in) << 32);
  var input1 = _read32(data, 0);
  var input2 = _read32(data, len - 4);
  var bitflip = (_secret64_at(8, 0) ^ _secret64_at(16, 0)) - seed;
  var input64 = input2 + (input1 << 32);
  return _rrmxmx(input64 ^ bitflip, len as UInt64);
}

fn _len_9to16_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  var bitflip1 = (_secret64_at(24, 0) ^ _secret64_at(32, 0)) + seed;
  var bitflip2 = (_secret64_at(40, 0) ^ _secret64_at(48, 0)) - seed;
  var input_lo = _read64(data, 0) ^ bitflip1;
  var input_hi = _read64(data, len - 8) ^ bitflip2;
  var acc = (len as UInt64) + _swap64(input_lo) + input_hi + _mul128_fold64(input_lo, input_hi);
  return _avalanche3(acc);
}

fn _len_0to16_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  if len > 8 { return _len_9to16_64(data, len, seed); }
  if len >= 4 { return _len_4to8_64(data, len, seed); }
  if len > 0 { return _len_1to3_64(data, len, seed); }
  return _avalanche64(seed ^ (_secret64_at(56, 0) ^ _secret64_at(64, 0)));
}

fn _len_17to128_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  var acc = (len as UInt64) * _P64_1;
  if len > 32 {
    if len > 64 {
      if len > 96 {
        acc = acc + _mix16b_at(data, 48, 96, seed);
        acc = acc + _mix16b_at(data, len - 64, 112, seed);
      }
      acc = acc + _mix16b_at(data, 32, 64, seed);
      acc = acc + _mix16b_at(data, len - 48, 80, seed);
    }
    acc = acc + _mix16b_at(data, 16, 32, seed);
    acc = acc + _mix16b_at(data, len - 32, 48, seed);
  }
  acc = acc + _mix16b_at(data, 0, 0, seed);
  acc = acc + _mix16b_at(data, len - 16, 16, seed);
  return _avalanche3(acc);
}

fn _len_129to240_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  var acc = (len as UInt64) * _P64_1;
  var i: Int = 0;
  while i < 8 {
    acc = acc + _mix16b_at(data, 16 * i, 16 * i, seed);
    i = i + 1;
  }
  var acc_end = _mix16b_at(data, len - 16, 119, seed);
  var nb = len / 16;
  var i2: Int = 8;
  while i2 < nb {
    acc_end = acc_end + _mix16b_at(data, 16 * i2, 3 + 16 * (i2 - 8), seed);
    i2 = i2 + 1;
  }
  return _avalanche3(acc + acc_end);
}

// ---- 64-bit long inputs (stripes + scramble) ----

// NOTE: the long path is only reached with the default secret (seed 0) in
// the reference when seed == 0; with a seed, v0.8.3 uses a 192-byte custom
// secret with +seed/-seed lanes. _secret64_at(off, 0) IS the default secret,
// so the seeded long path must use the seeded secret — handled by the caller
// via _hash_long_* with `seed` threaded through _scalar_round2 below.
fn _scalar_round2(acc: &mut Vec[UInt64], data: &Vec[UInt8], input_pos: Int, secret_off: Int, lane: Int, seed: UInt64) {
  var data_val = _read64(data, input_pos + lane * 8);
  var data_key = data_val ^ _secret64_at(secret_off + lane * 8, seed);
  var idx = lane ^ 1;
  acc[idx] = acc[idx] + data_val;
  var lo = data_key & 0xFFFFFFFF;
  var hi = _shr(data_key, 32);
  acc[lane] = _mult32to64(lo, hi) + acc[lane];
}

fn _accumulate(acc: &mut Vec[UInt64], data: &Vec[UInt8], input_pos: Int, secret_off: Int, nb_stripes: Int, seed: UInt64) {
  var s: Int = 0;
  while s < nb_stripes {
    var lane: Int = 0;
    while lane < 8 {
      _scalar_round2(acc, data, input_pos + s * 64, secret_off + s * 8, lane, seed);
      lane = lane + 1;
    }
    s = s + 1;
  }
}

fn _scramble(acc: &mut Vec[UInt64], secret_off: Int, seed: UInt64) {
  var lane: Int = 0;
  while lane < 8 {
    var v = _xorshift(acc[lane], 47);
    v = v ^ _secret64_at(secret_off + lane * 8, seed);
    v = v * _P32_1;
    acc[lane] = v;
    lane = lane + 1;
  }
}

fn _mix2accs(acc: &Vec[UInt64], idx: Int, secret_off: Int, seed: UInt64) -> UInt64 {
  return _mul128_fold64(
    acc[idx] ^ _secret64_at(secret_off, seed),
    acc[idx + 1] ^ _secret64_at(secret_off + 8, seed));
}

fn _merge_accs(acc: &Vec[UInt64], secret_off: Int, start: UInt64, seed: UInt64) -> UInt64 {
  var result = start;
  var i: Int = 0;
  while i < 4 {
    result = result + _mix2accs(acc, 2 * i, secret_off + 16 * i, seed);
    i = i + 1;
  }
  return _avalanche3(result);
}

fn _hash_long_64(data: &Vec[UInt8], len: Int, seed: UInt64) -> UInt64 {
  var acc = Vec[UInt64].new();
  acc.push(_P32_3);
  acc.push(_P64_1);
  acc.push(_P64_2);
  acc.push(_P64_3);
  acc.push(_P64_4);
  acc.push(_P32_2);
  acc.push(_P64_5);
  acc.push(_P32_1);
  var nb_stripes_per_block = (192 - 64) / 8;
  var block_len = 64 * nb_stripes_per_block;
  var nb_blocks = (len - 1) / block_len;
  var n: Int = 0;
  while n < nb_blocks {
    _accumulate(&mut acc, data, n * block_len, 0, nb_stripes_per_block, seed);
    _scramble(&mut acc, 192 - 64, seed);
    n = n + 1;
  }
  var nb_stripes = ((len - 1) - (block_len * nb_blocks)) / 64;
  _accumulate(&mut acc, data, nb_blocks * block_len, 0, nb_stripes, seed);
  _accumulate(&mut acc, data, len - 64, 192 - 64 - 7, 1, seed);
  return _merge_accs(&acc, 11, (len as UInt64) * _P64_1, seed);
}

// ---- 128-bit ----

pub type Xxh128 = { low64: UInt64; high64: UInt64; }

fn _len_1to3_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  var c1: UInt64 = data[0] as UInt64;
  var c2: UInt64 = data[len >> 1] as UInt64;
  var c3: UInt64 = data[len - 1] as UInt64;
  var combinedl: UInt64 = (c1 << 16) | (c2 << 24) | c3 | ((len as UInt64) << 8);
  var combinedh = _rotl32(_swap32(combinedl), 13);
  var bitflipl = (_secret32_at(0, 0) ^ _secret32_at(4, 0)) + seed;
  var bitfliph = (_secret32_at(8, 0) ^ _secret32_at(12, 0)) - seed;
  var keyed_lo = combinedl ^ bitflipl;
  var keyed_hi = combinedh ^ bitfliph;
  return Xxh128{ low64: _avalanche64(keyed_lo); high64: _avalanche64(keyed_hi); };
}

fn _len_4to8_128(data: &Vec[UInt8], len: Int, seed_in: UInt64) -> Xxh128 {
  var seed = seed_in ^ (_swap32(seed_in) << 32);
  var input_lo = _read32(data, 0);
  var input_hi = _read32(data, len - 4);
  var input_64 = input_lo + (input_hi << 32);
  var bitflip = (_secret64_at(16, 0) ^ _secret64_at(24, 0)) + seed;
  var keyed = input_64 ^ bitflip;
  var m = _mult64to128(keyed, _P64_1 + ((len as UInt64) << 2));
  var mlow = m.lo;
  var mhigh = m.hi;
  mhigh = mhigh + (mlow << 1);
  mlow = mlow ^ _shr(mhigh, 3);
  mlow = _xorshift(mlow, 35);
  mlow = mlow * _MX2;
  mlow = _xorshift(mlow, 28);
  mhigh = _avalanche3(mhigh);
  return Xxh128{ low64: mlow; high64: mhigh; };
}

fn _len_9to16_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  var bitflipl = (_secret64_at(32, 0) ^ _secret64_at(40, 0)) - seed;
  var bitfliph = (_secret64_at(48, 0) ^ _secret64_at(56, 0)) + seed;
  var input_lo = _read64(data, 0);
  var input_hi = _read64(data, len - 8);
  var m = _mult64to128(input_lo ^ input_hi ^ bitflipl, _P64_1);
  var mlow = m.lo;
  var mhigh = m.hi;
  mlow = mlow + (((len - 1) as UInt64) << 54);
  input_hi = input_hi ^ bitfliph;
  mhigh = mhigh + input_hi + _mult32to64(input_hi, _P32_2 - 1);
  mlow = mlow ^ _swap64(mhigh);
  var h = _mult64to128(mlow, _P64_2);
  var hlow = h.lo;
  var hhigh = h.hi + mhigh * _P64_2;
  return Xxh128{ low64: _avalanche3(hlow); high64: _avalanche3(hhigh); };
}

fn _len_0to16_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  if len > 8 { return _len_9to16_128(data, len, seed); }
  if len >= 4 { return _len_4to8_128(data, len, seed); }
  if len > 0 { return _len_1to3_128(data, len, seed); }
  var z: UInt64 = 0;
  var bitflipl = _secret64_at(64, 0) ^ _secret64_at(72, 0);
  var bitfliph = _secret64_at(80, 0) ^ _secret64_at(88, 0);
  return Xxh128{ low64: _avalanche64(seed ^ bitflipl); high64: _avalanche64((z - seed) ^ bitfliph); };
}

fn _mix32b(acc_low: UInt64, acc_high: UInt64, data: &Vec[UInt8], pos1: Int, pos2: Int, off: Int, seed: UInt64) -> U64Pair {
  var low = acc_low + _mix16b_at(data, pos1, off, seed);
  low = low ^ (_read64(data, pos2) + _read64(data, pos2 + 8));
  var high = acc_high + _mix16b_at(data, pos2, off + 16, seed);
  high = high ^ (_read64(data, pos1) + _read64(data, pos1 + 8));
  return U64Pair{ lo: low; hi: high; };
}

fn _len_17to128_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  var alow = (len as UInt64) * _P64_1;
  var ahigh: UInt64 = 0;
  if len > 32 {
    if len > 64 {
      if len > 96 {
        var m1 = _mix32b(alow, ahigh, data, 48, len - 64, 96, seed);
        alow = m1.lo;
        ahigh = m1.hi;
      }
      var m2 = _mix32b(alow, ahigh, data, 32, len - 48, 64, seed);
      alow = m2.lo;
      ahigh = m2.hi;
    }
    var m3 = _mix32b(alow, ahigh, data, 16, len - 32, 32, seed);
    alow = m3.lo;
    ahigh = m3.hi;
  }
  var m4 = _mix32b(alow, ahigh, data, 0, len - 16, 0, seed);
  alow = m4.lo;
  ahigh = m4.hi;
  var low = alow + ahigh;
  var high = alow * _P64_1 + ahigh * _P64_4 + ((len as UInt64) - seed) * _P64_2;
  var z: UInt64 = 0;
  return Xxh128{ low64: _avalanche3(low); high64: z - _avalanche3(high); };
}

fn _len_129to240_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  var alow = (len as UInt64) * _P64_1;
  var ahigh: UInt64 = 0;
  var i: Int = 32;
  while i < 160 {
    var m = _mix32b(alow, ahigh, data, i - 32, i - 16, i - 32, seed);
    alow = m.lo;
    ahigh = m.hi;
    i = i + 32;
  }
  alow = _avalanche3(alow);
  ahigh = _avalanche3(ahigh);
  var i2: Int = 160;
  while i2 <= len {
    var m2 = _mix32b(alow, ahigh, data, i2 - 32, i2 - 16, 3 + i2 - 160, seed);
    alow = m2.lo;
    ahigh = m2.hi;
    i2 = i2 + 32;
  }
  var z: UInt64 = 0;
  var m3 = _mix32b(alow, ahigh, data, len - 16, len - 32, 103, z - seed);
  alow = m3.lo;
  ahigh = m3.hi;
  var low = alow + ahigh;
  var high = alow * _P64_1 + ahigh * _P64_4 + ((len as UInt64) - seed) * _P64_2;
  return Xxh128{ low64: _avalanche3(low); high64: z - _avalanche3(high); };
}

fn _hash_long_128(data: &Vec[UInt8], len: Int, seed: UInt64) -> Xxh128 {
  var acc = Vec[UInt64].new();
  acc.push(_P32_3);
  acc.push(_P64_1);
  acc.push(_P64_2);
  acc.push(_P64_3);
  acc.push(_P64_4);
  acc.push(_P32_2);
  acc.push(_P64_5);
  acc.push(_P32_1);
  var nb_stripes_per_block = (192 - 64) / 8;
  var block_len = 64 * nb_stripes_per_block;
  var nb_blocks = (len - 1) / block_len;
  var n: Int = 0;
  while n < nb_blocks {
    _accumulate(&mut acc, data, n * block_len, 0, nb_stripes_per_block, seed);
    _scramble(&mut acc, 192 - 64, seed);
    n = n + 1;
  }
  var nb_stripes = ((len - 1) - (block_len * nb_blocks)) / 64;
  _accumulate(&mut acc, data, nb_blocks * block_len, 0, nb_stripes, seed);
  _accumulate(&mut acc, data, len - 64, 192 - 64 - 7, 1, seed);
  var low = _merge_accs(&acc, 11, (len as UInt64) * _P64_1, seed);
  var z: UInt64 = 0;
  var high = _merge_accs(&acc, 192 - 64 - 11, z - ((len as UInt64) * _P64_2), seed);
  return Xxh128{ low64: low; high64: high; };
}

// ---- public API ----

/// XXH3-64, seed 0. Verified against xxHash v0.8.3 reference: "" →
/// 0x2d06800538d394c2, "a" → 0xe6c632b61e964e1f, "abc" → 0x78af5f94892f3950.
pub fn xxh3_64(data: &Vec[UInt8]) -> UInt64 {
  return xxh3_64_with_seed(data, 0);
}

/// XXH3-64 with an explicit 64-bit seed (v0.8.3 seeded-secret semantics).
pub fn xxh3_64_with_seed(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  var len = data.len();
  if len <= 16 { return _len_0to16_64(data, len, seed); }
  if len <= 128 { return _len_17to128_64(data, len, seed); }
  if len <= 240 { return _len_129to240_64(data, len, seed); }
  return _hash_long_64(data, len, seed);
}

/// XXH3-128, seed 0. Verified against xxHash v0.8.3 reference: "" →
/// (0x6001c324468d497f, 0x99aa06d3014798d8), "a" →
/// (0xe6c632b61e964e1f, 0xa96faf705af16834).
pub fn xxh3_128(data: &Vec[UInt8]) -> Xxh128 {
  return xxh3_128_with_seed(data, 0);
}

/// XXH3-128 with an explicit 64-bit seed (v0.8.3 seeded-secret semantics).
pub fn xxh3_128_with_seed(data: &Vec[UInt8], seed: UInt64) -> Xxh128 {
  var len = data.len();
  if len <= 16 { return _len_0to16_128(data, len, seed); }
  if len <= 128 { return _len_17to128_128(data, len, seed); }
  if len <= 240 { return _len_129to240_128(data, len, seed); }
  return _hash_long_128(data, len, seed);
}














