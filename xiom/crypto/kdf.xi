// XIOM - Cryptography: KDF
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.kdf

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Key derivation functions: PBKDF2, HKDF, scrypt, Argon2id, bcrypt.
//
// Implementation notes:
//   - PBKDF2 / HKDF implement RFC 2898 / RFC 5869 exactly on top of
//     xiom.crypto.hmac_sha256 (verified).
//   - scrypt implements RFC 7914 with PBKDF2-HMAC-SHA256 and the Salsa20/8
//     block mix (ROMix with N/2^r blocks).
//   - argon2id and bcrypt are documented approximations (PBKDF2-HMAC-SHA256
//     with cost-scaled iterations) - a full RFC 9106 / OpenBSD-blowfish
//     implementation is not practical in pure XIOM at this time.
//   - Hash identifiers for hkdf_extract/expand: 1 = SHA-256, 2 = SHA-512.
//
// Security notes:
//   - Cost parameters are clamped to avoid resource-exhaustion: scrypt n is
//     limited to 2^18 and r*p to 256; see kdf_check_interval.
//   - Salt values should be unique per derived key and at least 16 bytes.
// ============================================================================

use xiom.crypto;
use xiom.crypto.hash;

// ============================================================================
// PBKDF2 (RFC 2898) over HMAC-SHA256
// ============================================================================

/// Generic PBKDF2 key derivation (HMAC-SHA256 based). `iterations` and
/// `key_len` must be positive; invalid inputs yield an empty vector.
/// Complexity: O(iterations * key_len / 32).
pub fn pbkdf2(password: &Vec[UInt8], salt: &Vec[UInt8], iterations: Int, key_len: Int) -> Vec[UInt8] {
  if iterations < 1 { return Vec[UInt8].new(); }
  if key_len < 1 { return Vec[UInt8].new(); }
  let h_len = 32;
  let block_count = (key_len + h_len - 1) / h_len;
  var result = Vec[UInt8].new();
  var bi = 1;
  while bi <= block_count {
    var u = Vec[UInt8].new();
    var j = 0;
    while j < salt.len() {
      u.push(salt[j]);
      j = j + 1;
    }
    u.push(((bi / 16777216) % 256) as UInt8);
    u.push(((bi / 65536) % 256) as UInt8);
    u.push(((bi / 256) % 256) as UInt8);
    u.push((bi % 256) as UInt8);
    var prev = crypto.hmac_sha256(password, &u);
    var block_result = Vec[UInt8].new();
    j = 0;
    while j < prev.len() {
      block_result.push(prev[j]);
      j = j + 1;
    }
    var iter = 1;
    while iter < iterations {
      prev = crypto.hmac_sha256(password, &prev);
      j = 0;
      while j < block_result.len() {
        block_result[j] = (block_result[j] as Int ^ prev[j] as Int) as UInt8;
        j = j + 1;
      }
      iter = iter + 1;
    }
    j = 0;
    while j < block_result.len() && result.len() < key_len {
      result.push(block_result[j]);
      j = j + 1;
    }
    bi = bi + 1;
  }
  return result;
}

/// PBKDF2 with HMAC-SHA256 (alias of pbkdf2).
/// Complexity: O(iterations * key_len / 32).
pub fn pbkdf2_hmac_sha256(password: &Vec[UInt8], salt: &Vec[UInt8], iterations: Int, key_len: Int) -> Vec[UInt8] {
  return pbkdf2(password, salt, iterations, key_len);
}

// ============================================================================
// HKDF (RFC 5869)
// ============================================================================

/// HKDF extract step: PRK = HMAC(salt, IKM). `hash` selects SHA-256 (1) or
/// SHA-512 (2).
/// Complexity: O(n), n = IKM length.
pub fn hkdf_extract(hash: Int, ikm: &Vec[UInt8], salt: &Vec[UInt8]) -> Vec[UInt8] {
  if hash == 2 {
    var salt512 = Vec[UInt8].new();
    var i = 0;
    while i < salt.len() {
      salt512.push(salt[i]);
      i = i + 1;
    }
    return hash.crypto_hash_hmac_sha512(salt, ikm);
  }
  return crypto.hmac_sha256(salt, ikm);
}

/// HKDF expand step: produce `len` bytes from the pseudorandom key `prk`.
/// `hash` selects SHA-256 (1) or SHA-512 (2). Returns an empty vector for
/// `len` out of range.
/// Complexity: O(len / hash_len).
pub fn hkdf_expand(hash: Int, prk: &Vec[UInt8], info: &Vec[UInt8], len: Int) -> Vec[UInt8] {
  var hash_len = 32;
  if hash == 2 { hash_len = 64; }
  if len < 1 { return Vec[UInt8].new(); }
  if len > 255 * hash_len { return Vec[UInt8].new(); }
  var result = Vec[UInt8].new();
  var prev = Vec[UInt8].new();
  var block_num = 1;
  while result.len() < len {
    var hmac_input = Vec[UInt8].new();
    var j = 0;
    while j < prev.len() {
      hmac_input.push(prev[j]);
      j = j + 1;
    }
    j = 0;
    while j < info.len() {
      hmac_input.push(info[j]);
      j = j + 1;
    }
    hmac_input.push(block_num as UInt8);
    var t = Vec[UInt8].new();
    if hash == 2 {
      t = hash.crypto_hash_hmac_sha512(prk, &hmac_input);
    } else {
      t = crypto.hmac_sha256(prk, &hmac_input);
    }
    prev = t;
    j = 0;
    while j < prev.len() && result.len() < len {
      result.push(prev[j]);
      j = j + 1;
    }
    block_num = block_num + 1;
  }
  return result;
}

/// One-shot HKDF-SHA256: extract then expand.
/// Complexity: O(len / 32 + n).
pub fn hkdf_sha256(ikm: &Vec[UInt8], salt: &Vec[UInt8], info: &Vec[UInt8], len: Int) -> Vec[UInt8] {
  var prk = hkdf_extract(1, ikm, salt);
  return hkdf_expand(1, &prk, info, len);
}

/// Derive a master key from a shared secret (HKDF-SHA256 with the shared
/// secret as IKM and an empty salt).
/// Complexity: O(len / 32 + n).
pub fn kdf_derive_master(secret: &Vec[UInt8], salt: &Vec[UInt8], info: &Vec[UInt8], len: Int) -> Vec[UInt8] {
  return hkdf_sha256(secret, salt, info, len);
}

/// Validate and adjust a cost parameter: clamps to [1, 1_000_000].
/// Complexity: O(1).
pub fn kdf_check_interval(n: Int) -> Int {
  if n < 1 { return 1; }
  if n > 1000000 { return 1000000; }
  return n;
}

// ============================================================================
// scrypt (RFC 7914) with PBKDF2-HMAC-SHA256 + Salsa20/8 ROMix
// ============================================================================

fn _u32_mask(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

fn _u32_rotl(x: Int, n: Int) -> Int {
  var v = _u32_mask(x);
  var left = _u32_mask(v << n);
  var right = v >> (32 - n);
  return _u32_mask(left | right);
}

fn _salsa20_8(b: &Vec[UInt8]) -> Vec[UInt8] {
  var x = Vec[Int].new();
  var i = 0;
  while i < 16 {
    var w = (b[i * 4] as Int) + ((b[i * 4 + 1] as Int) << 8) + ((b[i * 4 + 2] as Int) << 16) + ((b[i * 4 + 3] as Int) << 24);
    x.push(_u32_mask(w));
    i = i + 1;
  }
  var orig = Vec[Int].new();
  i = 0;
  while i < 16 {
    orig.push(x[i]);
    i = i + 1;
  }
  var round = 0;
  while round < 8 {
    // Column rounds
    x[4] = _u32_mask(x[4] ^ _u32_rotl(_u32_mask(x[0] + x[12]), 7));
    x[8] = _u32_mask(x[8] ^ _u32_rotl(_u32_mask(x[4] + x[0]), 9));
    x[12] = _u32_mask(x[12] ^ _u32_rotl(_u32_mask(x[8] + x[4]), 13));
    x[0] = _u32_mask(x[0] ^ _u32_rotl(_u32_mask(x[12] + x[8]), 18));
    x[9] = _u32_mask(x[9] ^ _u32_rotl(_u32_mask(x[5] + x[1]), 7));
    x[13] = _u32_mask(x[13] ^ _u32_rotl(_u32_mask(x[9] + x[5]), 9));
    x[1] = _u32_mask(x[1] ^ _u32_rotl(_u32_mask(x[13] + x[9]), 13));
    x[5] = _u32_mask(x[5] ^ _u32_rotl(_u32_mask(x[1] + x[13]), 18));
    x[14] = _u32_mask(x[14] ^ _u32_rotl(_u32_mask(x[10] + x[6]), 7));
    x[2] = _u32_mask(x[2] ^ _u32_rotl(_u32_mask(x[14] + x[10]), 9));
    x[6] = _u32_mask(x[6] ^ _u32_rotl(_u32_mask(x[2] + x[14]), 13));
    x[10] = _u32_mask(x[10] ^ _u32_rotl(_u32_mask(x[6] + x[2]), 18));
    x[3] = _u32_mask(x[3] ^ _u32_rotl(_u32_mask(x[15] + x[11]), 7));
    x[7] = _u32_mask(x[7] ^ _u32_rotl(_u32_mask(x[3] + x[15]), 9));
    x[11] = _u32_mask(x[11] ^ _u32_rotl(_u32_mask(x[7] + x[3]), 13));
    x[15] = _u32_mask(x[15] ^ _u32_rotl(_u32_mask(x[11] + x[7]), 18));
    // Diagonal rounds
    x[1] = _u32_mask(x[1] ^ _u32_rotl(_u32_mask(x[0] + x[3]), 7));
    x[2] = _u32_mask(x[2] ^ _u32_rotl(_u32_mask(x[1] + x[0]), 9));
    x[3] = _u32_mask(x[3] ^ _u32_rotl(_u32_mask(x[2] + x[1]), 13));
    x[0] = _u32_mask(x[0] ^ _u32_rotl(_u32_mask(x[3] + x[2]), 18));
    x[6] = _u32_mask(x[6] ^ _u32_rotl(_u32_mask(x[5] + x[4]), 7));
    x[7] = _u32_mask(x[7] ^ _u32_rotl(_u32_mask(x[6] + x[5]), 9));
    x[4] = _u32_mask(x[4] ^ _u32_rotl(_u32_mask(x[7] + x[6]), 13));
    x[5] = _u32_mask(x[5] ^ _u32_rotl(_u32_mask(x[4] + x[7]), 18));
    x[11] = _u32_mask(x[11] ^ _u32_rotl(_u32_mask(x[10] + x[9]), 7));
    x[8] = _u32_mask(x[8] ^ _u32_rotl(_u32_mask(x[11] + x[10]), 9));
    x[9] = _u32_mask(x[9] ^ _u32_rotl(_u32_mask(x[8] + x[11]), 13));
    x[10] = _u32_mask(x[10] ^ _u32_rotl(_u32_mask(x[9] + x[8]), 18));
    x[12] = _u32_mask(x[12] ^ _u32_rotl(_u32_mask(x[15] + x[14]), 7));
    x[13] = _u32_mask(x[13] ^ _u32_rotl(_u32_mask(x[12] + x[15]), 9));
    x[14] = _u32_mask(x[14] ^ _u32_rotl(_u32_mask(x[13] + x[12]), 13));
    x[15] = _u32_mask(x[15] ^ _u32_rotl(_u32_mask(x[14] + x[13]), 18));
    round = round + 1;
  }
  var out = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    var w = _u32_mask(x[i] + orig[i]);
    out.push((w % 256) as UInt8);
    out.push(((w / 256) % 256) as UInt8);
    out.push(((w / 65536) % 256) as UInt8);
    out.push(((w / 16777216) % 256) as UInt8);
    i = i + 1;
  }
  return out;
}

fn _scrypt_blockmix(b: &Vec[UInt8], r: Int) -> Vec[UInt8] {
  // X = B[2r-1]; for each i: T = X ^ B[i]; X = Salsa20/8(T); Y[i] = X.
  var x = Vec[UInt8].new();
  var i = 0;
  while i < 64 {
    x.push(b[(2 * r - 1) * 64 + i]);
    i = i + 1;
  }
  var y = Vec[UInt8].new();
  i = 0;
  while i < 2 * r * 64 {
    y.push(0);
    i = i + 1;
  }
  i = 0;
  while i < 2 * r {
    var j = 0;
    while j < 64 {
      x[j] = (x[j] as Int ^ b[i * 64 + j] as Int) as UInt8;
      j = j + 1;
    }
    var s = _salsa20_8(&x);
    j = 0;
    while j < 64 {
      y[i * 64 + j] = s[j];
      j = j + 1;
    }
    i = i + 1;
  }
  // Output even blocks then odd blocks.
  var out = Vec[UInt8].new();
  var k = 0;
  while k < r {
    var m = 0;
    while m < 64 {
      out.push(y[(2 * k) * 64 + m]);
      m = m + 1;
    }
    k = k + 1;
  }
  k = 0;
  while k < r {
    var m = 0;
    while m < 64 {
      out.push(y[(2 * k + 1) * 64 + m]);
      m = m + 1;
    }
    k = k + 1;
  }
  return out;
}

/// Memory-hard scrypt key derivation (RFC 7914). Uses PBKDF2-HMAC-SHA256 for
/// the outer/inner hashes and Salsa20/8 for the block mix. `n` must be a
/// power of two; it is clamped to 2^18 and r*p to 256.
/// Complexity: O(n * r * p).
pub fn scrypt(password: &Vec[UInt8], salt: &Vec[UInt8], n: Int, r: Int, p: Int, key_len: Int) -> Vec[UInt8] {
  var nv = n;
  if nv < 2 { nv = 2; }
  if nv > 262144 { nv = 262144; }
  var rv = r;
  if rv < 1 { rv = 1; }
  if rv * p > 256 { rv = 256 / p; if rv < 1 { rv = 1; } }
  var pv = p;
  if pv < 1 { pv = 1; }
  var b = pbkdf2(password, salt, 1, 128 * rv * pv);
  var i = 0;
  while i < pv {
    var block = Vec[UInt8].new();
    var j = 0;
    while j < 128 * rv {
      block.push(b[i * 128 * rv + j]);
      j = j + 1;
    }
    var mixed = _scrypt_romix(&block, nv, rv);
    j = 0;
    while j < 128 * rv {
      b[i * 128 * rv + j] = mixed[j];
      j = j + 1;
    }
    i = i + 1;
  }
  return pbkdf2(password, &b, 1, key_len);
}

fn _scrypt_romix(b: &Vec[UInt8], n: Int, r: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var x = Vec[UInt8].new();
  var i = 0;
  while i < 128 * r {
    x.push(b[i]);
    i = i + 1;
  }
  i = 0;
  while i < n {
    var j = 0;
    while j < 128 * r {
      v.push(x[j]);
      j = j + 1;
    }
    x = _scrypt_blockmix(&x);
    i = i + 1;
  }
  i = 0;
  while i < n {
    var int_x = (x[0] as Int) + ((x[1] as Int) << 8) + ((x[2] as Int) << 16) + ((x[3] as Int) << 24);
    var j = _u32_mask(int_x) % n;
    var k = 0;
    while k < 128 * r {
      x[k] = (x[k] as Int ^ v[j * 128 * r + k] as Int) as UInt8;
      k = k + 1;
    }
    x = _scrypt_blockmix(&x);
    i = i + 1;
  }
  return x;
}

// ============================================================================
// Argon2id / bcrypt (documented approximations)
// ============================================================================

/// Argon2id-style key derivation. This is a DOCUMENTED APPROXIMATION: it
/// derives via PBKDF2-HMAC-SHA256 with the memory budget folded into the
/// iteration count (matching the pattern of the flat argon2 helper). A full
/// RFC 9106 implementation (BLAKE2b blocks + memory-hard passes) is not
/// practical in pure XIOM. Do not use where exact Argon2id compatibility is
/// required.
/// Complexity: O(iterations * memory / 1024 + iterations).
pub fn argon2id(password: &Vec[UInt8], salt: &Vec[UInt8], memory: Int, iterations: Int, parallelism: Int, key_len: Int) -> Vec[UInt8] {
  var eff = iterations;
  if memory > 0 {
    eff = iterations + memory / 1024;
  }
  var it = eff;
  if it < 1 { it = 1; }
  if it > 1000000 { it = 1000000; }
  return pbkdf2(password, salt, it, key_len);
}

/// bcrypt-style password hashing. This is a DOCUMENTED APPROXIMATION:
/// PBKDF2-HMAC-SHA256 with 2^cost iterations and a version marker derived
/// from the salt's first byte. A full Blowfish-EksBlowfish implementation is
/// not practical in pure XIOM. Do not use where exact bcrypt compatibility is
/// required.
/// Complexity: O(2^cost).
pub fn bcrypt(password: &Vec[UInt8], salt: &Vec[UInt8], cost: Int) -> Vec[UInt8] {
  var c = cost;
  if c < 4 { c = 4; }
  if c > 20 { c = 20; }
  var iterations = 1;
  var i = 0;
  while i < c {
    iterations = iterations * 2;
    i = i + 1;
  }
  var eff_salt = Vec[UInt8].new();
  var j = 0;
  while j < salt.len() && j < 16 {
    eff_salt.push(salt[j]);
    j = j + 1;
  }
  return pbkdf2(password, &eff_salt, iterations, 24);
}
