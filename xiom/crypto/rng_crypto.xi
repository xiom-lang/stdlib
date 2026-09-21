// XIOM - Cryptography: RNG
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.rng_crypto

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Cryptographically secure random number generation.
//
// All functions build on xiom.crypto.secure_random_bytes (the OS-entropy
// CSPRNG), so they inherit its entropy source and are not reproducible from
// a seed.
//
// SECURITY STATUS: OS-entropy backed (ProcessPrng/RtlGenRandom on Windows,
// /dev/urandom on Unix) since the confined-block growth fix (COMPILER_BUGS.md
// R4). Degraded mode: if no OS source answers, the internal fallback draws
// from the OS-seeded legacy LCG -- a no-OS environment must be treated as
// insecure regardless.
//
// Security notes:
//   - crypto_random_uniform uses rejection sampling over a 32-bit draw so the
//     result is unbiased for any n in [1, 2^32).
//   - crypto_random_float takes the top 53 bits of a 64-bit draw, giving a
//     uniform double in [0, 1).
//   - crypto_random_prime returns a probable prime (Miller-Rabin via BigInt);
//     the primality test is probabilistic (error bound < 2^-128 for the
//     default rounds used by the bigint module).
// ============================================================================

use xiom.crypto;
use xiom.string;
use xiom.bigint;
use xiom.num;

/// Fill `len` bytes from the CSPRNG. Negative lengths return an empty vector.
/// Complexity: O(len).
pub fn crypto_random_bytes(len: Int) -> Vec[UInt8] {
  if len < 0 { return Vec[UInt8].new(); }
  return crypto.secure_random_bytes(len);
}

/// Random 64-bit unsigned integer.
/// Complexity: O(1).
pub fn crypto_random_u64() -> UInt64 {
  var bytes = crypto.secure_random_bytes(8);
  var r: UInt64 = 0;
  var i = 0;
  while i < 8 {
    r = r | ((bytes[i] as UInt64) << (i * 8));
    i = i + 1;
  }
  return r;
}

/// Random 32-bit unsigned integer.
/// Complexity: O(1).
pub fn crypto_random_u32() -> UInt32 {
  var bytes = crypto.secure_random_bytes(4);
  var b0 = bytes[0] as Int;
  var b1 = bytes[1] as Int;
  var b2 = bytes[2] as Int;
  var b3 = bytes[3] as Int;
  return (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)) as UInt32;
}

/// Unbiased random integer in [0, n). Returns 0 for n <= 0.
/// Complexity: O(1) expected.
pub fn crypto_random_uniform(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 0; }
  var bound = 4294967295;
  if n > bound {
    var u = _draw_u32();
    return u % n;
  }
  var limit = bound - (bound % n);
  var r: Int = 0;
  var done = false;
  while done == false {
    var u = _draw_u32();
    if u < limit {
      r = u % n;
      done = true;
    }
  }
  return r;
}

fn _draw_u32() -> Int {
  var bytes = crypto.secure_random_bytes(4);
  var b0 = bytes[0] as Int;
  var b1 = bytes[1] as Int;
  var b2 = bytes[2] as Int;
  var b3 = bytes[3] as Int;
  return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
}

fn _u64_lshr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { return 0 as UInt64; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

/// Random double in [0, 1). Uses the top 53 bits of a 64-bit draw.
/// Complexity: O(1).
pub fn crypto_random_float() -> Float64 {
  var u = crypto_random_u64();
  var top = num.f64_from_u64(_u64_lshr(u, 11));
  return top / 9007199254740992.0;
}

/// Fair random boolean.
/// Complexity: O(1).
pub fn crypto_random_bool() -> Bool {
  var bytes = crypto.secure_random_bytes(1);
  return (bytes[0] as Int) % 2 == 0;
}

/// Fisher-Yates shuffle in place using the CSPRNG.
/// Complexity: O(n), n = vector length.
pub fn crypto_random_shuffle[T](v: &mut Vec[T]) {
  var i = v.len();
  while i > 1 {
    var j = crypto_random_uniform(i);
    var tmp = v[i - 1];
    v[i - 1] = v[j];
    v[j] = tmp;
    i = i - 1;
  }
}

/// Pick a uniformly random element, or None for an empty vector.
/// Complexity: O(1).
pub fn crypto_random_choice[T](v: &Vec[T]) -> Option[T] {
  if v.len() == 0 {
    return None;
  }
  var idx = crypto_random_uniform(v.len());
  return Some(v[idx]);
}

/// Seed value gathered from system entropy (8 bytes).
/// Complexity: O(1).
pub fn crypto_seed_from_entropy() -> UInt64 {
  return crypto_random_u64();
}

/// Generate a probable prime of the given bit length (big-endian bytes).
/// Uses bigint_is_prime (probabilistic). Returns an empty vector on invalid
/// bit lengths or failure.
/// Complexity: expected O(bits^4) with rejection.
pub fn crypto_random_prime(bits: Int) -> Vec[UInt8] {
  if bits < 16 || bits > 2048 { return Vec[UInt8].new(); }
  var byte_len = (bits + 7) / 8;
  var found = false;
  var result = Vec[UInt8].new();
  while found == false {
    var cand = crypto.secure_random_bytes(byte_len);
    // Force the top bit and an odd value.
    cand[0] = (cand[0] as Int | 0x80) as UInt8;
    var last = cand[byte_len - 1] as Int;
    if last % 2 == 0 {
      last = last + 1;
    }
    cand[byte_len - 1] = last as UInt8;
    var hex = xiom.encoding.hex_encode(&cand);
    var bint = bigint.bigint_from_hex(hex);
    match bint {
      Ok(bi) => {
        if bigint.bigint_is_prime(&bi) {
          result = cand;
          found = true;
        }
      }
      Err(_) => {}
    }
  }
  return result;
}

/// Random string drawn from an alphabet (uniform via the CSPRNG). Returns an
/// empty string when the alphabet is empty or `len` is negative.
/// Complexity: O(len).
pub fn crypto_random_string(len: Int, alphabet: Str) -> Str {
  if len < 0 { return ""; }
  if alphabet.len() == 0 { return ""; }
  var result = "";
  var i = 0;
  while i < len {
    var idx = crypto_random_uniform(alphabet.len());
    var opt = xiom.string.char_at(alphabet, idx);
    if opt.is_some {
      result = result + xiom.string.str_slice(alphabet, idx, idx + 1);
    }
    i = i + 1;
  }
  return result;
}
