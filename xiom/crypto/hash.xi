// XIOM - Cryptography: Hash
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.hash

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Cryptographic hash functions and HMAC/PBKDF2/HKDF helpers.
//
// Delegation strategy:
//   - crypto_hash_sha256 / crypto_hash_sha256_hex / crypto_hash_md5 /
//     crypto_hash_hmac_sha256 delegate to the flat xiom.crypto module (the
//     same-named functions there are verified).
//   - SHA-512 is implemented HERE with a corrected 64-bit rotate. The flat
//     module's _u64_rotr performs an arithmetic right shift for negative
//     operands, which corrupts digests whenever a 64-bit word has its top bit
//     set (verified: xiom.crypto.sha512 fails its test vector in the current
//     build). Local SHA-512, BLAKE2b, HMAC-SHA512 and the hex wrapper all use
//     the corrected logical rotate.
//   - SHA-1 and BLAKE2b have no flat equivalent and are implemented here.
//
// Security notes:
//   - SHA-1 and MD5 are legacy: collisions are practical. Interop only.
//   - BLAKE2b (RFC 7693) outputs 64 bytes and is unkeyed here.
//   - HMAC follows RFC 2104; PBKDF2 follows RFC 2898; HKDF follows RFC 5869.
// ============================================================================

use xiom.crypto;
use xiom.encoding;
use xiom.string;

const _HMAC_BLOCK_SHA256: Int = 64;
const _HMAC_BLOCK_SHA512: Int = 128;
const _HMAC_BLOCK_MD5: Int = 64;
const _HMAC_BLOCK_SHA1: Int = 64;

// ============================================================================
// 32-bit helpers (SHA-1)
// ============================================================================

fn _u32_mask(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

fn _pow2(n: Int) -> Int {
  var p = 1;
  var i = 0;
  while i < n {
    p = p * 2;
    i = i + 1;
  }
  return p;
}

fn _u32_rotr(x: Int, n: Int) -> Int {
  var v = _u32_mask(x);
  var right = v / _pow2(n);
  var left = _u32_mask(v * _pow2(32 - n));
  return _u32_mask(right | left);
}

fn _u32_rotl(x: Int, n: Int) -> Int {
  return _u32_rotr(x, 32 - n);
}

fn _u32_shl(a: Int, n: Int) -> Int {
  var x = _u32_mask(a);
  if n <= 0 { return x; }
  if n >= 32 { return 0; }
  return _u32_mask(x * _pow2(n));
}

fn _u32_add(a: Int, b: Int) -> Int {
  return _u32_mask(a + b);
}

// ============================================================================
// MD5 (RFC 1321). 16-byte digest. Local implementation: the flat module's
// md5 is broken in the current build (its test vector fails). Legacy, interop
// only.
// ============================================================================

const _MD5_S: [64]Int = [
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
];

const _MD5_K: [64]Int = [
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
];

fn _md5_f(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask((x & y) | ((~x) & z));
}

fn _md5_g(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask((x & z) | (y & (~z)));
}

fn _md5_h(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask(x ^ y ^ z);
}

fn _md5_i(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask(y ^ (x | (~z)));
}

fn _md5_compute(data: &Vec[UInt8]) -> Vec[UInt8] {
  let data_len = data.len();
  let bit_len = data_len * 8;
  var pad_len = 64 - ((data_len + 9) % 64);
  if pad_len >= 64 { pad_len = pad_len - 64; }
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data_len {
    padded.push(data[i]);
    i = i + 1;
  }
  padded.push(0x80);
  i = 0;
  while i < pad_len {
    padded.push(0);
    i = i + 1;
  }
  // Little-endian 64-bit bit length
  var bl = bit_len;
  i = 0;
  while i < 8 {
    padded.push((bl % 256) as UInt8);
    bl = bl / 256;
    i = i + 1;
  }
  var a: Int = 0x67452301;
  var b: Int = 0xefcdab89;
  var c: Int = 0x98badcfe;
  var d: Int = 0x10325476;
  let blocks = padded.len() / 64;
  var bi = 0;
  while bi < blocks {
    var m: [16]Int;
    var j = 0;
    while j < 16 {
      let b0 = padded[bi * 64 + j * 4 + 0] as Int;
      let b1 = padded[bi * 64 + j * 4 + 1] as Int;
      let b2 = padded[bi * 64 + j * 4 + 2] as Int;
      let b3 = padded[bi * 64 + j * 4 + 3] as Int;
      m[j] = b0 | (b1 * 256) | (b2 * 65536) | (b3 * 16777216);
      j = j + 1;
    }
    var aa = a;
    var bb = b;
    var cc = c;
    var dd = d;
    // Round loop split into 4 chunks of 16 (single 64-iteration loops can
    // miscompile in called functions; see module header).
    var chunk_i = 0;
    while chunk_i < 4 {
      var chunk = chunk_i * 16;
      var end = chunk + 16;
      j = chunk;
      while j < end {
        var f_val: Int = 0;
        var g: Int = 0;
        if j < 16 {
          f_val = _md5_f(b, c, d);
          g = j;
        } elif j < 32 {
          f_val = _md5_g(b, c, d);
          g = (5 * j + 1) % 16;
          if g < 0 { g = g + 16; }
        } elif j < 48 {
          f_val = _md5_h(b, c, d);
          g = (3 * j + 5) % 16;
          if g < 0 { g = g + 16; }
        } else {
          f_val = _md5_i(b, c, d);
          g = (7 * j) % 16;
          if g < 0 { g = g + 16; }
        }
        var temp = d;
        d = c;
        c = b;
        b = _u32_add(b, _u32_rotl(_u32_add(_u32_add(a, f_val), _u32_add(_MD5_K[j], m[g])), _MD5_S[j]));
        a = temp;
        j = j + 1;
      }
      chunk_i = chunk_i + 1;
    }
    a = _u32_add(a, aa);
    b = _u32_add(b, bb);
    c = _u32_add(c, cc);
    d = _u32_add(d, dd);
    bi = bi + 1;
  }
  var result = Vec[UInt8].new();
  result.push((a % 256) as UInt8);
  result.push(((a / 256) % 256) as UInt8);
  result.push(((a / 65536) % 256) as UInt8);
  result.push(((a / 16777216) % 256) as UInt8);
  result.push((b % 256) as UInt8);
  result.push(((b / 256) % 256) as UInt8);
  result.push(((b / 65536) % 256) as UInt8);
  result.push(((b / 16777216) % 256) as UInt8);
  result.push((c % 256) as UInt8);
  result.push(((c / 256) % 256) as UInt8);
  result.push(((c / 65536) % 256) as UInt8);
  result.push(((c / 16777216) % 256) as UInt8);
  result.push((d % 256) as UInt8);
  result.push(((d / 256) % 256) as UInt8);
  result.push(((d / 65536) % 256) as UInt8);
  result.push(((d / 16777216) % 256) as UInt8);
  return result;
}

// ============================================================================
// 64-bit helpers (SHA-512 / BLAKE2b). Logical rotate: the right part must
// zero-fill, so negative operands are handled as unsigned (the flat module's
// rotate is arithmetic here and corrupts high-bit words).
// ============================================================================

fn _u64_lshr(x: Int, n: Int) -> Int {
  if n <= 0 { return x; }
  if n >= 64 { return 0; }
  var p = _pow2(n);
  if x >= 0 { return x / p; }
  var q = x / p;
  if (x % p) != 0 { q = q - 1; }
  return q + _pow2(64 - n);
}

fn _u64_rotr(x: Int, n: Int) -> Int {
  if n <= 0 { return x; }
  if n >= 64 { return x; }
  var right = _u64_lshr(x, n);
  var left = x * _pow2(64 - n);
  return right | left;
}

fn _u64_shr(x: Int, n: Int) -> Int {
  if n <= 0 { return x; }
  if n >= 64 { return 0; }
  var p = _pow2(n);
  if x >= 0 { return x / p; }
  var q = x / p;
  if (x % p) != 0 { q = q - 1; }
  return q + _pow2(64 - n);
}

/// SHA-1 (FIPS 180-1). 20-byte digest. Legacy, interop only.
pub fn crypto_hash_sha1(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 20
{
  let data_len = data.len();
  let bit_len = data_len * 8;
  var pad_len = 64 - ((data_len + 9) % 64);
  if pad_len >= 64 { pad_len = pad_len - 64; }
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data_len {
    padded.push(data[i]);
    i = i + 1;
  }
  padded.push(0x80);
  i = 0;
  while i < pad_len {
    padded.push(0);
    i = i + 1;
  }
  // Big-endian 64-bit bit length: reserve 8 zero bytes, fill MSB..LSB.
  var bl = bit_len;
  i = 0;
  while i < 8 {
    padded.push(0);
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    padded[data_len + 9 + pad_len - 1 - i] = (bl % 256) as UInt8;
    bl = bl / 256;
    i = i + 1;
  }
  var h0: Int = 0x67452301;
  var h1: Int = 0xEFCDAB89;
  var h2: Int = 0x98BADCFE;
  var h3: Int = 0x10325476;
  var h4: Int = 0xC3D2E1F0;
  let blocks = padded.len() / 64;
  var bi = 0;
  while bi < blocks {
    var w: [80]Int;
    var j = 0;
    while j < 16 {
      let b0 = padded[bi * 64 + j * 4 + 0] as Int;
      let b1 = padded[bi * 64 + j * 4 + 1] as Int;
      let b2 = padded[bi * 64 + j * 4 + 2] as Int;
      let b3 = padded[bi * 64 + j * 4 + 3] as Int;
      w[j] = _u32_mask((b0 * 16777216) + (b1 * 65536) + (b2 * 256) + b3);
      j = j + 1;
    }
    j = 16;
    while j < 80 {
      w[j] = _u32_rotl(_u32_mask(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16]), 1);
      j = j + 1;
    }
    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    j = 0;
    while j < 80 {
      var f_val: Int = 0;
      var k_val: Int = 0;
      if j < 20 {
        f_val = _u32_mask((b & c) | ((~b) & d));
        k_val = 0x5A827999;
      } elif j < 40 {
        f_val = _u32_mask(b ^ c ^ d);
        k_val = 0x6ED9EBA1;
      } elif j < 60 {
        f_val = _u32_mask((b & c) | (b & d) | (c & d));
        k_val = 0x8F1BBCDC;
      } else {
        f_val = _u32_mask(b ^ c ^ d);
        k_val = 0xCA62C1D6;
      }
      let temp = _u32_mask(_u32_mask(_u32_rotl(a, 5)) + f_val + e + k_val + w[j]);
      e = d;
      d = c;
      c = _u32_rotr(b, 2);
      b = a;
      a = temp;
      j = j + 1;
    }
    h0 = _u32_mask(h0 + a);
    h1 = _u32_mask(h1 + b);
    h2 = _u32_mask(h2 + c);
    h3 = _u32_mask(h3 + d);
    h4 = _u32_mask(h4 + e);
    bi = bi + 1;
  }
  var result = Vec[UInt8].new();
  result.push(((h0 / 16777216) % 256) as UInt8);
  result.push(((h0 / 65536) % 256) as UInt8);
  result.push(((h0 / 256) % 256) as UInt8);
  result.push((h0 % 256) as UInt8);
  result.push(((h1 / 16777216) % 256) as UInt8);
  result.push(((h1 / 65536) % 256) as UInt8);
  result.push(((h1 / 256) % 256) as UInt8);
  result.push((h1 % 256) as UInt8);
  result.push(((h2 / 16777216) % 256) as UInt8);
  result.push(((h2 / 65536) % 256) as UInt8);
  result.push(((h2 / 256) % 256) as UInt8);
  result.push((h2 % 256) as UInt8);
  result.push(((h3 / 16777216) % 256) as UInt8);
  result.push(((h3 / 65536) % 256) as UInt8);
  result.push(((h3 / 256) % 256) as UInt8);
  result.push((h3 % 256) as UInt8);
  result.push(((h4 / 16777216) % 256) as UInt8);
  result.push(((h4 / 65536) % 256) as UInt8);
  result.push(((h4 / 256) % 256) as UInt8);
  result.push((h4 % 256) as UInt8);
  return result;
}

// ============================================================================
// SHA-512 (FIPS 180-4). 64-byte digest. Local implementation with the
// corrected 64-bit rotate (see module header).
// ============================================================================

fn _sha512_k_constants() -> Vec[Int] {
  var k = Vec[Int].new();
  k.push(0x428a2f98d728ae22); k.push(0x7137449123ef65cd); k.push(0xb5c0fbcfec4d3b2f); k.push(0xe9b5dba58189dbbc);
  k.push(0x3956c25bf348b538); k.push(0x59f111f1b605d019); k.push(0x923f82a4af194f9b); k.push(0xab1c5ed5da6d8118);
  k.push(0xd807aa98a3030242); k.push(0x12835b0145706fbe); k.push(0x243185be4ee4b28c); k.push(0x550c7dc3d5ffb4e2);
  k.push(0x72be5d74f27b896f); k.push(0x80deb1fe3b1696b1); k.push(0x9bdc06a725c71235); k.push(0xc19bf174cf692694);
  k.push(0xe49b69c19ef14ad2); k.push(0xefbe4786384f25e3); k.push(0x0fc19dc68b8cd5b5); k.push(0x240ca1cc77ac9c65);
  k.push(0x2de92c6f592b0275); k.push(0x4a7484aa6ea6e483); k.push(0x5cb0a9dcbd41fbd4); k.push(0x76f988da831153b5);
  k.push(0x983e5152ee66dfab); k.push(0xa831c66d2db43210); k.push(0xb00327c898fb213f); k.push(0xbf597fc7beef0ee4);
  k.push(0xc6e00bf33da88fc2); k.push(0xd5a79147930aa725); k.push(0x06ca6351e003826f); k.push(0x142929670a0e6e70);
  k.push(0x27b70a8546d22ffc); k.push(0x2e1b21385c26c926); k.push(0x4d2c6dfc5ac42aed); k.push(0x53380d139d95b3df);
  k.push(0x650a73548baf63de); k.push(0x766a0abb3c77b2a8); k.push(0x81c2c92e47edaee6); k.push(0x92722c851482353b);
  k.push(0xa2bfe8a14cf10364); k.push(0xa81a664bbc423001); k.push(0xc24b8b70d0f89791); k.push(0xc76c51a30654be30);
  k.push(0xd192e819d6ef5218); k.push(0xd69906245565a910); k.push(0xf40e35855771202a); k.push(0x106aa07032bbd1b8);
  k.push(0x19a4c116b8d2d0c8); k.push(0x1e376c085141ab53); k.push(0x2748774cdf8eeb99); k.push(0x34b0bcb5e19b48a8);
  k.push(0x391c0cb3c5c95a63); k.push(0x4ed8aa4ae3418acb); k.push(0x5b9cca4f7763e373); k.push(0x682e6ff3d6b2b8a3);
  k.push(0x748f82ee5defb2fc); k.push(0x78a5636f43172f60); k.push(0x84c87814a1f0ab72); k.push(0x8cc702081a6439ec);
  k.push(0x90befffa23631e28); k.push(0xa4506cebde82bde9); k.push(0xbef9a3f7b2c67915); k.push(0xc67178f2e372532b);
  k.push(0xca273eceea26619c); k.push(0xd186b8c721c0c207); k.push(0xeada7dd6cde0eb1e); k.push(0xf57d4f7fee6ed178);
  k.push(0x06f067aa72176fba); k.push(0x0a637dc5a2c898a6); k.push(0x113f9804bef90dae); k.push(0x1b710b35131c471b);
  k.push(0x28db77f523047d84); k.push(0x32caab7b40c72493); k.push(0x3c9ebe0a15c9bebc); k.push(0x431d67c49c100d4c);
  k.push(0x4cc5d4becb3e42b6); k.push(0x597f299cfc657e2a); k.push(0x5fcb6fab3ad6faec); k.push(0x6c44198c4a475817);
  return k;
}

fn _sha512_iv() -> Vec[Int] {
  var v = Vec[Int].new();
  v.push(0x6a09e667f3bcc908);
  v.push(0xbb67ae8584caa73b);
  v.push(0x3c6ef372fe94f82b);
  v.push(0xa54ff53a5f1d36f1);
  v.push(0x510e527fade682d1);
  v.push(0x9b05688c2b3e6c1f);
  v.push(0x1f83d9abfb41bd6b);
  v.push(0x5be0cd19137e2179);
  return v;
}

fn _sha512_block(block: &Vec[UInt8], start: Int, state: &mut Vec[Int]) {
  var k = _sha512_k_constants();
  var w: [80]Int;
  var i = 0;
  while i < 16 {
    var val: Int = 0;
    var j = 0;
    while j < 8 {
      val = val * 256 + (block[start + i * 8 + j] as Int);
      j = j + 1;
    }
    w[i] = val;
    i = i + 1;
  }
  i = 16;
  while i < 80 {
    var e1 = _u64_rotr(w[i - 2], 19) ^ _u64_rotr(w[i - 2], 61) ^ _u64_shr(w[i - 2], 6);
    var e0 = _u64_rotr(w[i - 15], 1) ^ _u64_rotr(w[i - 15], 8) ^ _u64_shr(w[i - 15], 7);
    w[i] = e1 + w[i - 7] + e0 + w[i - 16];
    i = i + 1;
  }
  var a = state[0];
  var b = state[1];
  var c = state[2];
  var d = state[3];
  var e = state[4];
  var f = state[5];
  var g = state[6];
  var h = state[7];
  i = 0;
  while i < 80 {
    let s1 = _u64_rotr(e, 14) ^ _u64_rotr(e, 18) ^ _u64_rotr(e, 41);
    let ch = (e & f) ^ ((~e) & g);
    let t1 = h + s1 + ch + k[i] + w[i];
    let s0 = _u64_rotr(a, 28) ^ _u64_rotr(a, 34) ^ _u64_rotr(a, 39);
    let maj = (a & b) ^ (a & c) ^ (b & c);
    let t2 = s0 + maj;
    h = g;
    g = f;
    f = e;
    e = d + t1;
    d = c;
    c = b;
    b = a;
    a = t1 + t2;
    i = i + 1;
  }
  state[0] = state[0] + a;
  state[1] = state[1] + b;
  state[2] = state[2] + c;
  state[3] = state[3] + d;
  state[4] = state[4] + e;
  state[5] = state[5] + f;
  state[6] = state[6] + g;
  state[7] = state[7] + h;
}

fn _sha512_compress(data: &Vec[UInt8]) -> Vec[Int] {
  let data_len = data.len();
  let bit_len = data_len * 8;
  var pad_len = 128 - ((data_len + 17) % 128);
  if pad_len >= 128 { pad_len = pad_len - 128; }
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data_len {
    padded.push(data[i]);
    i = i + 1;
  }
  padded.push(0x80);
  i = 0;
  while i < pad_len {
    padded.push(0);
    i = i + 1;
  }
  // Big-endian 128-bit bit length: reserve 16 bytes, fill the low 8 MSB..LSB.
  var bl = bit_len;
  i = 0;
  while i < 16 {
    padded.push(0);
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    padded[data_len + 16 + pad_len - i] = (bl % 256) as UInt8;
    bl = bl / 256;
    i = i + 1;
  }
  var state = _sha512_iv();
  let block_count = padded.len() / 128;
  var bi = 0;
  while bi < block_count {
    _sha512_block(&padded, bi * 128, &mut state);
    bi = bi + 1;
  }
  return state;
}

// ============================================================================
// BLAKE2b (RFC 7693). 64-byte digest.
// ============================================================================

fn _blake2b_iv() -> Vec[Int] {
  var v = Vec[Int].new();
  v.push(0x6a09e667f3bcc908);
  v.push(0xbb67ae8584caa73b);
  v.push(0x3c6ef372fe94f82b);
  v.push(0xa54ff53a5f1d36f1);
  v.push(0x510e527fade682d1);
  v.push(0x9b05688c2b3e6c1f);
  v.push(0x1f83d9abfb41bd6b);
  v.push(0x5be0cd19137e2179);
  return v;
}

fn _blake2b_sigma() -> Vec[Int] {
  var s = Vec[Int].new();
  s.push(0); s.push(1); s.push(2); s.push(3); s.push(4); s.push(5); s.push(6); s.push(7);
  s.push(8); s.push(9); s.push(10); s.push(11); s.push(12); s.push(13); s.push(14); s.push(15);
  s.push(14); s.push(10); s.push(4); s.push(8); s.push(9); s.push(15); s.push(13); s.push(6);
  s.push(1); s.push(12); s.push(0); s.push(2); s.push(11); s.push(7); s.push(5); s.push(3);
  s.push(11); s.push(8); s.push(12); s.push(0); s.push(5); s.push(2); s.push(15); s.push(13);
  s.push(10); s.push(14); s.push(3); s.push(6); s.push(7); s.push(1); s.push(9); s.push(4);
  s.push(7); s.push(9); s.push(3); s.push(1); s.push(13); s.push(12); s.push(11); s.push(14);
  s.push(2); s.push(6); s.push(5); s.push(10); s.push(4); s.push(0); s.push(15); s.push(8);
  s.push(9); s.push(0); s.push(5); s.push(7); s.push(2); s.push(4); s.push(10); s.push(15);
  s.push(14); s.push(1); s.push(11); s.push(12); s.push(6); s.push(8); s.push(3); s.push(13);
  s.push(2); s.push(12); s.push(6); s.push(10); s.push(0); s.push(11); s.push(8); s.push(3);
  s.push(4); s.push(13); s.push(7); s.push(5); s.push(15); s.push(14); s.push(1); s.push(9);
  s.push(12); s.push(5); s.push(1); s.push(15); s.push(14); s.push(13); s.push(4); s.push(10);
  s.push(0); s.push(7); s.push(6); s.push(3); s.push(9); s.push(2); s.push(8); s.push(11);
  s.push(13); s.push(11); s.push(7); s.push(14); s.push(12); s.push(1); s.push(3); s.push(9);
  s.push(5); s.push(0); s.push(15); s.push(4); s.push(8); s.push(6); s.push(2); s.push(10);
  s.push(6); s.push(15); s.push(14); s.push(9); s.push(11); s.push(3); s.push(0); s.push(8);
  s.push(12); s.push(2); s.push(13); s.push(7); s.push(1); s.push(4); s.push(10); s.push(5);
  s.push(10); s.push(2); s.push(8); s.push(4); s.push(7); s.push(6); s.push(1); s.push(5);
  s.push(15); s.push(11); s.push(9); s.push(14); s.push(3); s.push(12); s.push(13); s.push(0);
  return s;
}

fn _blake2b_g(v: &mut Vec[Int], a: Int, b: Int, c: Int, d: Int, x: Int, y: Int) {
  v[a] = v[a] + v[b] + x;
  v[d] = _u64_rotr(v[d] ^ v[a], 32);
  v[c] = v[c] + v[d];
  v[b] = _u64_rotr(v[b] ^ v[c], 24);
  v[a] = v[a] + v[b] + y;
  v[d] = _u64_rotr(v[d] ^ v[a], 16);
  v[c] = v[c] + v[d];
  v[b] = _u64_rotr(v[b] ^ v[c], 63);
}

fn _blake2b_load64(data: &Vec[UInt8], offset: Int) -> Int {
  var v: Int = 0;
  var i = 7;
  while i >= 0 {
    v = v * 256 + (data[offset + i] as Int);
    i = i - 1;
  }
  return v;
}

fn _blake2b_store64(out: &mut Vec[UInt8], v: Int) {
  var x = v;
  var i = 0;
  while i < 8 {
    out.push((x & 0xFF) as UInt8);
    x = x >> 8;
    i = i + 1;
  }
}

/// BLAKE2b-512 digest (64 bytes).
pub fn crypto_hash_blake2b(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 64
{
  let out_len = 64;
  let data_len = data.len();
  var sigma = _blake2b_sigma();
  var h = _blake2b_iv();
  h[0] = h[0] ^ 0x01010000 ^ out_len;
  var t0: Int = 0;
  var t1: Int = 0;
  var pos = 0;
  while data_len - pos > 128 {
    var m = Vec[Int].new();
    var j = 0;
    while j < 16 {
      m.push(_blake2b_load64(data, pos + j * 8));
      j = j + 1;
    }
    t0 = t0 + 128;
    if t0 < 0 { t1 = t1 + 1; }
    h = _blake2b_compress(&h, &m, &sigma, t0, t1, 0);
    pos = pos + 128;
  }
  var rem = data_len - pos;
  var m = Vec[Int].new();
  var j = 0;
  while j < 16 {
    var word: Int = 0;
    var k = 0;
    while k < 8 {
      if pos + j * 8 + k < data_len {
        word = word * 256 + (data[pos + j * 8 + k] as Int);
      } else {
        word = word * 256;
      }
      k = k + 1;
    }
    m.push(word);
    j = j + 1;
  }
  t0 = t0 + rem;
  if t0 < 0 { t1 = t1 + 1; }
  h = _blake2b_compress(&h, &m, &sigma, t0, t1, 1);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    _blake2b_store64(&mut result, h[i]);
    i = i + 1;
  }
  return result;
}

fn _blake2b_compress(h: &Vec[Int], m: &Vec[Int], sigma: &Vec[Int], t0: Int, t1: Int, last: Int) -> Vec[Int] {
  var v = Vec[Int].new();
  var i = 0;
  while i < 8 {
    v.push(h[i]);
    i = i + 1;
  }
  var iv = _blake2b_iv();
  i = 0;
  while i < 8 {
    v.push(iv[i]);
    i = i + 1;
  }
  v[12] = v[12] ^ t0;
  v[13] = v[13] ^ t1;
  if last != 0 {
    v[14] = ~v[14];
  }
  var r = 0;
  while r < 12 {
    var row_off = (r % 10) * 16;
    _blake2b_g(&mut v, 0, 4, 8, 12, m[sigma[row_off + 0]], m[sigma[row_off + 1]]);
    _blake2b_g(&mut v, 1, 5, 9, 13, m[sigma[row_off + 2]], m[sigma[row_off + 3]]);
    _blake2b_g(&mut v, 2, 6, 10, 14, m[sigma[row_off + 4]], m[sigma[row_off + 5]]);
    _blake2b_g(&mut v, 3, 7, 11, 15, m[sigma[row_off + 6]], m[sigma[row_off + 7]]);
    _blake2b_g(&mut v, 0, 5, 10, 15, m[sigma[row_off + 8]], m[sigma[row_off + 9]]);
    _blake2b_g(&mut v, 1, 6, 11, 12, m[sigma[row_off + 10]], m[sigma[row_off + 11]]);
    _blake2b_g(&mut v, 2, 7, 8, 13, m[sigma[row_off + 12]], m[sigma[row_off + 13]]);
    _blake2b_g(&mut v, 3, 4, 9, 14, m[sigma[row_off + 14]], m[sigma[row_off + 15]]);
    r = r + 1;
  }
  var result = Vec[Int].new();
  i = 0;
  while i < 8 {
    result.push(h[i] ^ v[i] ^ v[i + 8]);
    i = i + 1;
  }
  return result;
}

// ============================================================================
// Delegating wrappers
// ============================================================================

/// SHA-256 digest (32 bytes). Delegates to xiom.crypto.sha256.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_sha256(data: &Vec[UInt8]) -> Vec[UInt8] {
  return crypto.sha256(data);
}

/// SHA-512 digest (64 bytes). Implemented locally with the corrected 64-bit
/// rotate; the flat module's sha512 is not used (broken in the current build).
/// Complexity: O(n), n = input length.
pub fn crypto_hash_sha512(data: &Vec[UInt8]) -> Vec[UInt8] {
  var st = _sha512_compress(data);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    // SHA-512 words are big-endian; store LE then reverse.
    var tmp = Vec[UInt8].new();
    _blake2b_store64(&mut tmp, st[i]);
    var k = 7;
    while k >= 0 {
      result.push(tmp[k]);
      k = k - 1;
    }
    i = i + 1;
  }
  return result;
}

/// MD5 digest (16 bytes). Local implementation (the flat module's md5 fails
/// its test vector in the current build). Legacy, interop only.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_md5(data: &Vec[UInt8]) -> Vec[UInt8] {
  return _md5_compute(data);
}

/// SHA-256 digest as lowercase hex. Delegates to xiom.crypto.sha256_hex.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_sha256_hex(data: &Vec[UInt8]) -> Str {
  return crypto.sha256_hex(data);
}

/// SHA-512 digest as lowercase hex (128 characters).
/// Complexity: O(n), n = input length.
pub fn crypto_hash_sha512_hex(data: &Vec[UInt8]) -> Str {
  var h = crypto_hash_sha512(data);
  return encoding.hex_encode(&h);
}

/// Keyed SHA-256 MAC. Delegates to xiom.crypto.hmac_sha256.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_hmac_sha256(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  return crypto.hmac_sha256(key, data);
}

/// Keyed SHA-512 MAC (RFC 2104), built on the local SHA-512.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_hmac_sha512(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  return _hmac_compute(key, data, 2);
}

/// Keyed MD5 MAC (RFC 2104). Legacy, interop only.
/// Complexity: O(n), n = input length.
pub fn crypto_hash_hmac_md5(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  return _hmac_compute(key, data, 3);
}

/// PBKDF2-HMAC-SHA256 (RFC 2898): derive `len` key bytes from a password.
/// Complexity: O(iterations * len / 32).
pub fn crypto_hash_pbkdf2_sha256(password: &Vec[UInt8], salt: &Vec[UInt8], iterations: Int, len: Int) -> Vec[UInt8] {
  if iterations < 1 { return Vec[UInt8].new(); }
  if len < 1 { return Vec[UInt8].new(); }
  let h_len = 32;
  let block_count = (len + h_len - 1) / h_len;
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
    while j < block_result.len() && result.len() < len {
      result.push(block_result[j]);
      j = j + 1;
    }
    bi = bi + 1;
  }
  return result;
}

/// HKDF (RFC 5869) with SHA-256. `salt` may be empty (defaults to zeros).
/// Complexity: O(len / 32 + n).
pub fn crypto_hash_hkdf(ikm: &Vec[UInt8], salt: &Vec[UInt8], info: &Vec[UInt8], len: Int) -> Vec[UInt8] {
  if len < 1 { return Vec[UInt8].new(); }
  if len > 255 * 32 { return Vec[UInt8].new(); }
  var prk = crypto.hmac_sha256(salt, ikm);
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
    prev = crypto.hmac_sha256(&prk, &hmac_input);
    j = 0;
    while j < prev.len() && result.len() < len {
      result.push(prev[j]);
      j = j + 1;
    }
    block_num = block_num + 1;
  }
  return result;
}

// ============================================================================
// Private helpers
// ============================================================================

fn _hmac_block_size(hash: Int) -> Int {
  if hash == 2 { return _HMAC_BLOCK_SHA512; }
  if hash == 3 { return _HMAC_BLOCK_MD5; }
  if hash == 4 { return _HMAC_BLOCK_SHA1; }
  return _HMAC_BLOCK_SHA256;
}

fn _hmac_hash(hash: Int, data: &Vec[UInt8]) -> Vec[UInt8] {
  if hash == 2 { return crypto_hash_sha512(data); }
  if hash == 3 { return _md5_compute(data); }
  if hash == 4 { return crypto_hash_sha1(data); }
  return crypto.sha256(data);
}

fn _hmac_compute(key: &Vec[UInt8], data: &Vec[UInt8], hash: Int) -> Vec[UInt8] {
  var block = _hmac_block_size(hash);
  var norm_key = Vec[UInt8].new();
  if key.len() > block {
    var hashed = _hmac_hash(hash, key);
    var i = 0;
    while i < hashed.len() {
      norm_key.push(hashed[i]);
      i = i + 1;
    }
    while i < block {
      norm_key.push(0);
      i = i + 1;
    }
  } else {
    var i = 0;
    while i < key.len() {
      norm_key.push(key[i]);
      i = i + 1;
    }
    while i < block {
      norm_key.push(0);
      i = i + 1;
    }
  }
  var inner = Vec[UInt8].new();
  var i = 0;
  while i < block {
    let k = norm_key[i] as Int;
    inner.push((k ^ 0x36) as UInt8);
    i = i + 1;
  }
  i = 0;
  while i < data.len() {
    inner.push(data[i]);
    i = i + 1;
  }
  let inner_hash = _hmac_hash(hash, &inner);
  var outer = Vec[UInt8].new();
  i = 0;
  while i < block {
    let k = norm_key[i] as Int;
    outer.push((k ^ 0x5c) as UInt8);
    i = i + 1;
  }
  i = 0;
  while i < inner_hash.len() {
    outer.push(inner_hash[i]);
    i = i + 1;
  }
  return _hmac_hash(hash, &outer);
}
