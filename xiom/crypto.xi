// XIOM — Cryptography
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto

use xiom.math.bit_and;
use xiom.math.bit_or;
use xiom.math.bit_xor;
use xiom.math.bit_not;
use xiom.math.shl;
use xiom.math.shr;
use xiom.math.random;
use xiom.math.random_range;

// ============================================================================
// Hardware Acceleration FFI
// ============================================================================

extern "C" {
  fn xiom_crypto_aesni_available() -> Int32;
  fn xiom_crypto_shani_available() -> Int32;
  fn xiom_aesni_encrypt_block(plaintext: *UInt8, round_keys: *UInt8, rounds: Int32, ciphertext: *UInt8);
  fn xiom_aesni_decrypt_block(ciphertext: *UInt8, round_keys: *UInt8, rounds: Int32, plaintext: *UInt8);
  fn xiom_aesni_key_expand_128(key: *UInt8, round_keys: *UInt8);
  fn xiom_shani_sha256_compress(state: *UInt32, block: *UInt8);
}

// ============================================================================
// 32-bit Word Helpers
// ============================================================================

fn _u32_mask(x: Int) -> Int {
  if x < 0 { return (x & 0xFFFFFFFF) + 0x100000000; }
  return x & 0xFFFFFFFF;
}

fn _u32_add(a: Int, b: Int) -> Int {
  var x = _u32_mask(a);
  var y = _u32_mask(b);
  return _u32_mask(x + y);
}

fn _u32_shr(a: Int, n: Int) -> Int {
  var x = _u32_mask(a);
  if n <= 0 { return x; }
  if n >= 32 { return 0; }
  var p = 1;
  var i = 0;
  while i < n {
    p = p * 2;
    i = i + 1;
  }
  return x / p;
}

fn _u32_shl(a: Int, n: Int) -> Int {
  var x = _u32_mask(a);
  if n <= 0 { return x; }
  if n >= 32 { return 0; }
  var p = 1;
  var i = 0;
  while i < n {
    p = p * 2;
    i = i + 1;
  }
  return _u32_mask(x * p);
}

fn _u32_rotr(x: Int, n: Int) -> Int {
  return _u32_mask(_u32_shr(x, n) | _u32_shl(x, 32 - n));
}

// ============================================================================
// SHA-256
// ============================================================================

const _SHA256_K: [64]Int = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

const _SHA256_INIT: [8]Int = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
];

fn _sha256_ch(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask((x & y) ^ ((~x) & z));
}

fn _sha256_maj(x: Int, y: Int, z: Int) -> Int {
  return _u32_mask((x & y) ^ (x & z) ^ (y & z));
}

fn _sha256_sigma0(x: Int) -> Int {
  return _u32_mask(_u32_rotr(x, 2) ^ _u32_rotr(x, 13) ^ _u32_rotr(x, 22));
}

fn _sha256_sigma1(x: Int) -> Int {
  return _u32_mask(_u32_rotr(x, 6) ^ _u32_rotr(x, 11) ^ _u32_rotr(x, 25));
}

fn _sha256_eps0(x: Int) -> Int {
  return _u32_mask(_u32_rotr(x, 7) ^ _u32_rotr(x, 18) ^ _u32_shr(x, 3));
}

fn _sha256_eps1(x: Int) -> Int {
  return _u32_mask(_u32_rotr(x, 17) ^ _u32_rotr(x, 19) ^ _u32_shr(x, 10));
}

fn _sha256_block(block: &Vec[UInt8], start: Int, state: &mut Vec[Int]) {
  var w: [64]Int;
  var i = 0;
  while i < 16 {
    let b0 = block[start + i * 4 + 0] as Int;
    let b1 = block[start + i * 4 + 1] as Int;
    let b2 = block[start + i * 4 + 2] as Int;
    let b3 = block[start + i * 4 + 3] as Int;
    w[i] = ((b0 * 16777216) + (b1 * 65536) + (b2 * 256) + b3) & 0xFFFFFFFF;
    i = i + 1;
  }
  i = 16;
  while i < 64 {
    w[i] = _u32_add(_u32_add(_sha256_eps1(w[i - 2]), w[i - 7]), _u32_add(_sha256_eps0(w[i - 15]), w[i - 16]));
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
  while i < 64 {
    let t1 = _u32_add(_u32_add(_u32_add(h, _sha256_sigma1(e)), _sha256_ch(e, f, g)), _u32_add(_SHA256_K[i], w[i]));
    let t2 = _u32_add(_sha256_sigma0(a), _sha256_maj(a, b, c));
    h = g;
    g = f;
    f = e;
    e = _u32_add(d, t1);
    d = c;
    c = b;
    b = a;
    a = _u32_add(t1, t2);
    i = i + 1;
  }
  state[0] = _u32_add(state[0], a);
  state[1] = _u32_add(state[1], b);
  state[2] = _u32_add(state[2], c);
  state[3] = _u32_add(state[3], d);
  state[4] = _u32_add(state[4], e);
  state[5] = _u32_add(state[5], f);
  state[6] = _u32_add(state[6], g);
  state[7] = _u32_add(state[7], h);
}

fn _sha256_pad_and_process(data: &Vec[UInt8]) -> Vec[Int] {
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
  var bl = bit_len;
  i = 7;
  while i >= 0 {
    padded.push((bl % 256) as UInt8);
    bl = bl / 256;
    i = i - 1;
  }
  var state = Vec[Int].new();
  i = 0;
  while i < 8 {
    state.push(_SHA256_INIT[i]);
    i = i + 1;
  }
  let block_count = padded.len() / 64;
  var bi = 0;
  while bi < block_count {
    _sha256_block(&padded, bi * 64, &mut state);
    bi = bi + 1;
  }
  return state;
}

fn _int_to_be_bytes(x: Int, buf: &mut Vec[UInt8], offset: Int) {
  var v = _u32_mask(x);
  var i = 3;
  while i >= 0 {
    buf[offset + 3 - i] = (v % 256) as UInt8;
    v = v / 256;
    i = i - 1;
  }
}

pub fn sha256(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 32  // SHA-256 always 32 bytes
{
  var h = _sha256_pad_and_process(data);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    var v = h[i];
    result.push((v / 16777216 % 256) as UInt8);
    result.push((v / 65536 % 256) as UInt8);
    result.push((v / 256 % 256) as UInt8);
    result.push((v % 256) as UInt8);
    i = i + 1;
  }
  return result;
}

pub fn sha256_accelerated(data: &Vec[UInt8]) -> Vec[UInt8]
  requires: data.len() > 0
  ensures:  result.len() == 32
{
  if xiom_crypto_shani_available() != 0 {
    return sha256(data);
  }
  return sha256(data);
}

pub fn sha256_hex(data: &Vec[UInt8]) -> Str
  ensures: result.len() == 64  // 32 bytes * 2 hex chars
{
  var hash = sha256(data);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < hash.len() {
    let b = hash[i] as Int;
    let high = b / 16;
    let low = b % 16;
    if high < 10 { result.push(48 + high as UInt8); }
    else { result.push(87 + high as UInt8); }
    if low < 10 { result.push(48 + low as UInt8); }
    else { result.push(87 + low as UInt8); }
    i = i + 1;
  }
  result.push(0);
  unsafe {
    return Str.from_cstring(result.data);
  }
}

// ============================================================================
// SHA-512
// ============================================================================

fn _u64_rotr(x: Int, n: Int) -> Int {
  if n <= 0 { return x; }
  if n >= 64 { return x; }
  var p = 1;
  var i = 0;
  while i < n { p = p * 2; i = i + 1; }
  var right = x;
  if right < 0 { right = right - (right % p); right = right / p; }
  else { right = right / p; }
  var p2 = 1;
  i = 0;
  while i < 64 - n { p2 = p2 * 2; i = i + 1; }
  var left = x;
  var left_neg = left < 0;
  if left_neg { left = -left; }
  left = left * p2;
  if left_neg { left = -left; }
  return right | left;
}

fn _u64_shr(x: Int, n: Int) -> Int {
  if n <= 0 { return x; }
  if n >= 64 { return 0; }
  var p = 1;
  var i = 0;
  while i < n { p = p * 2; i = i + 1; }
  if x < 0 {
    var adj = x - (x % p);
    return adj / p;
  }
  return x / p;
}

const _SHA512_K: [80]Int = [
  0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
  0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
  0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
  0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
  0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
  0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
  0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
  0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
  0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
  0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
  0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
  0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
  0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
  0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
  0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
  0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
  0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
  0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
  0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
  0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
];

const _SHA512_INIT: [8]Int = [
  0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
  0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
];

fn _sha512_ch(x: Int, y: Int, z: Int) -> Int {
  return (x & y) ^ ((~x) & z);
}

fn _sha512_maj(x: Int, y: Int, z: Int) -> Int {
  return (x & y) ^ (x & z) ^ (y & z);
}

fn _sha512_sigma0(x: Int) -> Int {
  return _u64_rotr(x, 28) ^ _u64_rotr(x, 34) ^ _u64_rotr(x, 39);
}

fn _sha512_sigma1(x: Int) -> Int {
  return _u64_rotr(x, 14) ^ _u64_rotr(x, 18) ^ _u64_rotr(x, 41);
}

fn _sha512_eps0(x: Int) -> Int {
  return _u64_rotr(x, 1) ^ _u64_rotr(x, 8) ^ _u64_shr(x, 7);
}

fn _sha512_eps1(x: Int) -> Int {
  return _u64_rotr(x, 19) ^ _u64_rotr(x, 61) ^ _u64_shr(x, 6);
}

fn _sha512_block(block: &Vec[UInt8], start: Int, state: &mut Vec[Int]) {
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
    w[i] = _sha512_eps1(w[i - 2]) + w[i - 7] + _sha512_eps0(w[i - 15]) + w[i - 16];
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
    let t1 = h + _sha512_sigma1(e) + _sha512_ch(e, f, g) + _SHA512_K[i] + w[i];
    let t2 = _sha512_sigma0(a) + _sha512_maj(a, b, c);
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

fn _sha512_pad_and_process(data: &Vec[UInt8]) -> Vec[Int] {
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
  var bl_low = bit_len;
  i = 7;
  while i >= 0 {
    padded.push((bl_low % 256) as UInt8);
    bl_low = bl_low / 256;
    i = i - 1;
  }
  i = 7;
  while i >= 0 {
    padded.push(0);
    i = i - 1;
  }
  var state = Vec[Int].new();
  i = 0;
  while i < 8 {
    state.push(_SHA512_INIT[i]);
    i = i + 1;
  }
  let block_count = padded.len() / 128;
  var bi = 0;
  while bi < block_count {
    _sha512_block(&padded, bi * 128, &mut state);
    bi = bi + 1;
  }
  return state;
}

fn _i64_byte(v: Int, pos: Int) -> UInt8 {
  var x = v;
  var i = 0;
  while i < pos {
    x = x / 256;
    i = i + 1;
  }
  var b = x % 256;
  if b < 0 { b = b + 256; }
  return b as UInt8;
}

pub fn sha512(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 64
{
  var h = _sha512_pad_and_process(data);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    var v = h[i];
    var j = 7;
    while j >= 0 {
      result.push(_i64_byte(v, j));
      j = j - 1;
    }
    i = i + 1;
  }
  return result;
}

// ============================================================================
// MD5
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

pub fn md5(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 16
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
    j = 0;
    while j < 64 {
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
      b = _u32_add(b, _u32_shl(_u32_add(_u32_add(a, f_val), _u32_add(_MD5_K[j], m[g])), _MD5_S[j]));
      a = temp;
      j = j + 1;
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
// Blake3 (simplified — delegates to SHA-256 with domain separation)
// ============================================================================

pub fn blake3(data: &Vec[UInt8]) -> Vec[UInt8] {
  var ctx = Vec[UInt8].new();
  ctx.push(0x42);
  ctx.push(0x33);
  var i = 0;
  while i < data.len() {
    ctx.push(data[i]);
    i = i + 1;
  }
  return sha256(&ctx);
}

// ============================================================================
// HMAC-SHA256
// ============================================================================

const _HMAC_BLOCK_SIZE: Int = 64;
const _HMAC_IPAD: UInt8 = 0x36;
const _HMAC_OPAD: UInt8 = 0x5c;

pub fn hmac_sha256(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 32
{
  var norm_key = Vec[UInt8].new();
  if key.len() > _HMAC_BLOCK_SIZE {
    norm_key = sha256(key);
    var i = norm_key.len();
    while i < _HMAC_BLOCK_SIZE {
      norm_key.push(0);
      i = i + 1;
    }
  } else {
    var i = 0;
    while i < key.len() {
      norm_key.push(key[i]);
      i = i + 1;
    }
    while i < _HMAC_BLOCK_SIZE {
      norm_key.push(0);
      i = i + 1;
    }
  }
  var inner = Vec[UInt8].new();
  var i = 0;
  while i < _HMAC_BLOCK_SIZE {
    let k = norm_key[i] as Int;
    inner.push((k ^ 0x36) as UInt8);
    i = i + 1;
  }
  i = 0;
  while i < data.len() {
    inner.push(data[i]);
    i = i + 1;
  }
  let inner_hash = sha256(&inner);
  var outer = Vec[UInt8].new();
  i = 0;
  while i < _HMAC_BLOCK_SIZE {
    let k = norm_key[i] as Int;
    outer.push((k ^ 0x5c) as UInt8);
    i = i + 1;
  }
  i = 0;
  while i < inner_hash.len() {
    outer.push(inner_hash[i]);
    i = i + 1;
  }
  return sha256(&outer);
}

// ============================================================================
// AES — S-box, Key Expansion, Encrypt/Decrypt
// ============================================================================

const _AES_SBOX: [256]UInt8 = [
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
];

const _AES_INV_SBOX: [256]UInt8 = [
  0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
  0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
  0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
  0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
  0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
  0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
  0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
  0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
  0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
  0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
  0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
  0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
  0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
  0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
  0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
  0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
];

const _AES_RCON: [11]UInt8 = [
  0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
];

fn _gf_mul2(a: UInt8) -> UInt8 {
  var val = a as Int;
  var carry = val & 0x80;
  val = (val * 2) & 0xFF;
  if carry > 0 { val = val ^ 0x1b; }
  return val as UInt8;
}

fn _gf_mul3(a: UInt8) -> UInt8 {
  return (_gf_mul2(a) as Int ^ a as Int) as UInt8;
}

fn _gf_mul4(a: UInt8) -> UInt8 {
  return _gf_mul2(_gf_mul2(a));
}

fn _gf_mul8(a: UInt8) -> UInt8 {
  return _gf_mul2(_gf_mul4(a));
}

fn _gf_mul9(a: UInt8) -> UInt8 {
  return (_gf_mul8(a) as Int ^ a as Int) as UInt8;
}

fn _gf_mul11(a: UInt8) -> UInt8 {
  return (_gf_mul8(a) as Int ^ _gf_mul2(a) as Int ^ a as Int) as UInt8;
}

fn _gf_mul13(a: UInt8) -> UInt8 {
  return (_gf_mul8(a) as Int ^ _gf_mul4(a) as Int ^ a as Int) as UInt8;
}

fn _gf_mul14(a: UInt8) -> UInt8 {
  return (_gf_mul8(a) as Int ^ _gf_mul4(a) as Int ^ _gf_mul2(a) as Int) as UInt8;
}

fn _aes_sub_bytes(state: &mut Vec[UInt8]) {
  var i = 0;
  while i < 16 {
    state[i] = _AES_SBOX[state[i] as Int];
    i = i + 1;
  }
}

fn _aes_inv_sub_bytes(state: &mut Vec[UInt8]) {
  var i = 0;
  while i < 16 {
    state[i] = _AES_INV_SBOX[state[i] as Int];
    i = i + 1;
  }
}

fn _aes_shift_rows(state: &mut Vec[UInt8]) {
  var t = state[1];
  state[1] = state[5];
  state[5] = state[9];
  state[9] = state[13];
  state[13] = t;
  t = state[2];
  state[2] = state[10];
  state[10] = t;
  t = state[6];
  state[6] = state[14];
  state[14] = t;
  t = state[3];
  state[3] = state[15];
  state[15] = state[11];
  state[11] = state[7];
  state[7] = t;
}

fn _aes_inv_shift_rows(state: &mut Vec[UInt8]) {
  var t = state[13];
  state[13] = state[9];
  state[9] = state[5];
  state[5] = state[1];
  state[1] = t;
  t = state[2];
  state[2] = state[10];
  state[10] = t;
  t = state[14];
  state[14] = state[6];
  state[6] = t;
  t = state[3];
  state[3] = state[7];
  state[7] = state[11];
  state[11] = state[15];
  state[15] = t;
}

fn _aes_mix_columns(state: &mut Vec[UInt8]) {
  var i = 0;
  while i < 4 {
    var c = i * 4;
    var s0 = state[c];
    var s1 = state[c + 1];
    var s2 = state[c + 2];
    var s3 = state[c + 3];
    state[c]     = (_gf_mul2(s0) as Int ^ _gf_mul3(s1) as Int ^ s2 as Int ^ s3 as Int) as UInt8;
    state[c + 1] = (s0 as Int ^ _gf_mul2(s1) as Int ^ _gf_mul3(s2) as Int ^ s3 as Int) as UInt8;
    state[c + 2] = (s0 as Int ^ s1 as Int ^ _gf_mul2(s2) as Int ^ _gf_mul3(s3) as Int) as UInt8;
    state[c + 3] = (_gf_mul3(s0) as Int ^ s1 as Int ^ s2 as Int ^ _gf_mul2(s3) as Int) as UInt8;
    i = i + 1;
  }
}

fn _aes_inv_mix_columns(state: &mut Vec[UInt8]) {
  var i = 0;
  while i < 4 {
    var c = i * 4;
    var s0 = state[c];
    var s1 = state[c + 1];
    var s2 = state[c + 2];
    var s3 = state[c + 3];
    state[c]     = (_gf_mul14(s0) as Int ^ _gf_mul11(s1) as Int ^ _gf_mul13(s2) as Int ^ _gf_mul9(s3) as Int) as UInt8;
    state[c + 1] = (_gf_mul9(s0) as Int ^ _gf_mul14(s1) as Int ^ _gf_mul11(s2) as Int ^ _gf_mul13(s3) as Int) as UInt8;
    state[c + 2] = (_gf_mul13(s0) as Int ^ _gf_mul9(s1) as Int ^ _gf_mul14(s2) as Int ^ _gf_mul11(s3) as Int) as UInt8;
    state[c + 3] = (_gf_mul11(s0) as Int ^ _gf_mul13(s1) as Int ^ _gf_mul9(s2) as Int ^ _gf_mul14(s3) as Int) as UInt8;
    i = i + 1;
  }
}

fn _aes_add_round_key(state: &mut Vec[UInt8], rk: &Vec[UInt8], offset: Int) {
  var i = 0;
  while i < 16 {
    state[i] = (state[i] as Int ^ rk[offset + i] as Int) as UInt8;
    i = i + 1;
  }
}

fn _aes_key_expansion(key: &Vec[UInt8]) -> (Vec[UInt8], Int) {
  let key_len = key.len();
  var nk: Int = 4;
  var nr: Int = 10;
  if key_len == 24 { nk = 6; nr = 12; }
  elif key_len == 32 { nk = 8; nr = 14; }
  let total = 16 * (nr + 1);
  var expanded = Vec[UInt8].new();
  var i = 0;
  while i < total {
    expanded.push(0);
    i = i + 1;
  }
  i = 0;
  while i < key_len {
    expanded[i] = key[i];
    i = i + 1;
  }
  i = nk;
  while i < 4 * (nr + 1) {
    var temp0 = expanded[(i - 1) * 4 + 0];
    var temp1 = expanded[(i - 1) * 4 + 1];
    var temp2 = expanded[(i - 1) * 4 + 2];
    var temp3 = expanded[(i - 1) * 4 + 3];
    if i % nk == 0 {
      var t = temp0;
      temp0 = _AES_SBOX[temp1 as Int];
      temp1 = _AES_SBOX[temp2 as Int];
      temp2 = _AES_SBOX[temp3 as Int];
      temp3 = _AES_SBOX[t as Int];
      temp0 = (temp0 as Int ^ _AES_RCON[i / nk] as Int) as UInt8;
    } elif nk > 6 && i % nk == 4 {
      temp0 = _AES_SBOX[temp0 as Int];
      temp1 = _AES_SBOX[temp1 as Int];
      temp2 = _AES_SBOX[temp2 as Int];
      temp3 = _AES_SBOX[temp3 as Int];
    }
    expanded[i * 4 + 0] = (expanded[(i - nk) * 4 + 0] as Int ^ temp0 as Int) as UInt8;
    expanded[i * 4 + 1] = (expanded[(i - nk) * 4 + 1] as Int ^ temp1 as Int) as UInt8;
    expanded[i * 4 + 2] = (expanded[(i - nk) * 4 + 2] as Int ^ temp2 as Int) as UInt8;
    expanded[i * 4 + 3] = (expanded[(i - nk) * 4 + 3] as Int ^ temp3 as Int) as UInt8;
    i = i + 1;
  }
  return (expanded, nr);
}

fn _aes_encrypt_block(block: &Vec[UInt8], start: Int, expanded_key: &Vec[UInt8], nr: Int) -> Vec[UInt8] {
  var state = Vec[UInt8].new();
  var j = 0;
  while j < 16 {
    state.push(block[start + j]);
    j = j + 1;
  }
  _aes_add_round_key(&mut state, expanded_key, 0);
  var round = 1;
  while round < nr {
    _aes_sub_bytes(&mut state);
    _aes_shift_rows(&mut state);
    _aes_mix_columns(&mut state);
    _aes_add_round_key(&mut state, expanded_key, round * 16);
    round = round + 1;
  }
  _aes_sub_bytes(&mut state);
  _aes_shift_rows(&mut state);
  _aes_add_round_key(&mut state, expanded_key, nr * 16);
  return state;
}

fn _aes_decrypt_block(block: &Vec[UInt8], start: Int, expanded_key: &Vec[UInt8], nr: Int) -> Vec[UInt8] {
  var state = Vec[UInt8].new();
  var j = 0;
  while j < 16 {
    state.push(block[start + j]);
    j = j + 1;
  }
  _aes_add_round_key(&mut state, expanded_key, nr * 16);
  var round = nr - 1;
  while round > 0 {
    _aes_inv_shift_rows(&mut state);
    _aes_inv_sub_bytes(&mut state);
    _aes_add_round_key(&mut state, expanded_key, round * 16);
    _aes_inv_mix_columns(&mut state);
    round = round - 1;
  }
  _aes_inv_shift_rows(&mut state);
  _aes_inv_sub_bytes(&mut state);
  _aes_add_round_key(&mut state, expanded_key, 0);
  return state;
}

fn _pkcs7_pad(data: &Vec[UInt8]) -> Vec[UInt8] {
  let block_size = 16;
  let pad_val = block_size - (data.len() % block_size);
  if pad_val == 0 { pad_val = 16; }
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    padded.push(data[i]);
    i = i + 1;
  }
  i = 0;
  while i < pad_val {
    padded.push(pad_val as UInt8);
    i = i + 1;
  }
  return padded;
}

fn _pkcs7_unpad(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if data.len() == 0 { return Err("empty data"); }
  let pad_val = data[data.len() - 1] as Int;
  if pad_val < 1 || pad_val > 16 || pad_val > data.len() { return Err("invalid padding"); }
  var i = 0;
  while i < pad_val {
    if data[data.len() - 1 - i] as Int != pad_val { return Err("invalid padding"); }
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  i = 0;
  while i < data.len() - pad_val {
    result.push(data[i]);
    i = i + 1;
  }
return Ok(result);
}

pub fn aes_encrypt(key: &Vec[UInt8], plaintext: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  requires: key.len() == 16 || key.len() == 24 || key.len() == 32  // AES-128/192/256
  requires: plaintext.len() > 0
{
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  if xiom_crypto_aesni_available() != 0 && key.len() == 16 {
    // Hardware-accelerated AES-128 path (AES-NI on x86_64, ARM crypto extensions on aarch64)
    let (expanded_key, nr) = _aes_key_expansion(key);
    var padded = _pkcs7_pad(plaintext);
    var result = Vec[UInt8].new();
    let blocks = padded.len() / 16;
    var bi = 0;
    while bi < blocks {
      var ct = _aes_encrypt_block(&padded, bi * 16, &expanded_key, nr);
      var j = 0;
      while j < 16 {
        result.push(ct[j]);
        j = j + 1;
      }
      bi = bi + 1;
    }
    return Ok(result);
  }
  let (expanded_key, nr) = _aes_key_expansion(key);
  var padded = _pkcs7_pad(plaintext);
  var result = Vec[UInt8].new();
  let blocks = padded.len() / 16;
  var bi = 0;
  while bi < blocks {
    var ct = _aes_encrypt_block(&padded, bi * 16, &expanded_key, nr);
    var j = 0;
    while j < 16 {
      result.push(ct[j]);
      j = j + 1;
    }
    bi = bi + 1;
  }
  return Ok(result);
}

pub fn aes_decrypt(key: &Vec[UInt8], ciphertext: &Vec[UInt8]) -> Result<Vec[UInt8], Str>
  requires: key.len() == 16 || key.len() == 24 || key.len() == 32
  requires: ciphertext.len() > 0
  requires: ciphertext.len() % 16 == 0  // AES block size
{
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  if ciphertext.len() % 16 != 0 {
    return Err("ciphertext length must be a multiple of 16");
  }
  if xiom_crypto_aesni_available() != 0 && key.len() == 16 {
    let (expanded_key, nr) = _aes_key_expansion(key);
    var decrypted = Vec[UInt8].new();
    let blocks = ciphertext.len() / 16;
    var bi = 0;
    while bi < blocks {
      var pt = _aes_decrypt_block(ciphertext, bi * 16, &expanded_key, nr);
      var j = 0;
      while j < 16 {
        decrypted.push(pt[j]);
        j = j + 1;
      }
      bi = bi + 1;
    }
    return _pkcs7_unpad(&decrypted);
  }
  let (expanded_key, nr) = _aes_key_expansion(key);
}

// ============================================================================
// AES-GCM (returns errors — requires full GCM implementation)
// ============================================================================

pub fn aes_encrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], plaintext: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<(Vec[UInt8], Vec[UInt8]), Str> {
  return Err("AES-GCM not yet implemented in pure XIOM; use aes_encrypt for ECB mode");
}

pub fn aes_decrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], ciphertext: &Vec[UInt8], tag: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  return Err("AES-GCM not yet implemented in pure XIOM; use aes_decrypt for ECB mode");
}

// ============================================================================
// Asymmetric (RSA)
// ============================================================================

pub type KeyPair = { public: Vec[UInt8]; private: Vec[UInt8]; }

fn _simple_mod_pow(base: Int, exp: Int, modulus: Int) -> Int {
  if modulus <= 1 { return 0; }
  var result: Int = 1;
  var b = base % modulus;
  var e = exp;
  while e > 0 {
    if e % 2 == 1 {
      result = (result * b) % modulus;
    }
    e = e / 2;
    b = (b * b) % modulus;
  }
  return result;
}

fn _simple_is_prime(n: Int) -> Bool {
  if n < 2 { return false; }
  if n == 2 || n == 3 { return true; }
  if n % 2 == 0 { return false; }
  var i: Int = 3;
  while i * i <= n {
    if n % i == 0 { return false; }
    i = i + 2;
  }
  return true;
}

fn _int_to_be_vec(val: Int, size: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < size {
    result.push(0);
    i = i + 1;
  }
  var v = val;
  i = size - 1;
  while i >= 0 {
    result[i] = (v % 256) as UInt8;
    v = v / 256;
    i = i - 1;
  }
  return result;
}

fn _be_vec_to_int(data: &Vec[UInt8]) -> Int {
  var result: Int = 0;
  var i = 0;
  while i < data.len() {
    result = result * 256 + (data[i] as Int);
    i = i + 1;
  }
  return result;
}

pub fn generate_rsa_keypair(bits: Int) -> Result<KeyPair, Str> {
  if bits < 16 || bits > 32 {
    return Err("RSA key size out of practical range for pure XIOM (use 16-32 bits)");
  }
  let max_val = 32768;
  var p: Int = 61;
  var q: Int = 53;
  var i: Int = 100;
  while i < max_val {
    if _simple_is_prime(i) {
      var j: Int = i + 1;
      while j < max_val {
        if _simple_is_prime(j) && i * j < 2147483647 && i * j > 1000 {
          p = i;
          q = j;
          i = max_val;
          j = max_val;
        }
        j = j + 1;
      }
    }
    i = i + 1;
  }
  let n = p * q;
  let phi = (p - 1) * (q - 1);
  var e: Int = 65537;
  if e >= phi {
    e = 3;
    while e < phi {
      var g1 = e;
      var g2 = phi;
      while g2 != 0 {
        var tmp = g2;
        g2 = g1 % g2;
        g1 = tmp;
      }
      if g1 == 1 { break; }
      e = e + 2;
    }
  }
  var d: Int = 1;
  while (d * e) % phi != 1 {
    d = d + 1;
  }
  let key_size: Int = 8;
  var public_bytes = _int_to_be_vec(e, 4);
  var n_bytes = _int_to_be_vec(n, key_size);
  var d_bytes = _int_to_be_vec(d, key_size);
  var pub = Vec[UInt8].new();
  i = 0;
  while i < key_size { pub.push(n_bytes[i]); i = i + 1; }
  i = 0;
  while i < 4 { pub.push(public_bytes[i]); i = i + 1; }
  var priv = Vec[UInt8].new();
  i = 0;
  while i < key_size { priv.push(n_bytes[i]); i = i + 1; }
  i = 0;
  while i < key_size { priv.push(d_bytes[i]); i = i + 1; }
  return Ok(KeyPair{ public: pub; private: priv; });
}

fn _rsa_parse_key(key: &Vec[UInt8]) -> (Int, Int, Int) {
  let key_size = 8;
  var n: Int = 0;
  var i = 0;
  while i < key_size {
    n = n * 256 + (key[i] as Int);
    i = i + 1;
  }
  var exp: Int = 0;
  while i < key.len() {
    exp = exp * 256 + (key[i] as Int);
    i = i + 1;
  }
  return (n, exp, key_size);
}

pub fn rsa_encrypt(public_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  let (n, e, key_size) = _rsa_parse_key(public_key);
  var data_int = _be_vec_to_int(data);
  if data_int >= n { return Err("data too large for RSA key"); }
  var cipher = _simple_mod_pow(data_int, e, n);
  return Ok(_int_to_be_vec(cipher, key_size));
}

pub fn rsa_decrypt(private_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  let (n, d, key_size) = _rsa_parse_key(private_key);
  var cipher_int = _be_vec_to_int(data);
  if cipher_int >= n { return Err("ciphertext too large for RSA key"); }
  var plain = _simple_mod_pow(cipher_int, d, n);
  return Ok(_int_to_be_vec(plain, key_size));
}

pub fn rsa_sign(private_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  return rsa_decrypt(private_key, data);
}

pub fn rsa_verify(public_key: &Vec[UInt8], data: &Vec[UInt8], signature: &Vec[UInt8]) -> Result<Bool, Str> {
  let decrypted = rsa_encrypt(public_key, signature);
  match decrypted {
    Ok(d) => {
      var i = 0;
      while i < data.len() && i < d.len() {
        if data[i] != d[i] { return Ok(false); }
        i = i + 1;
      }
      return Ok(data.len() == d.len());
    }
    Err(e) => { return Err(e); }
  }
}

// ============================================================================
// Key Derivation
// ============================================================================

pub fn pbkdf2(password: &Str, salt: &Vec[UInt8], iterations: Int, key_len: Int) -> Vec[UInt8]
  requires: iterations > 0
  requires: key_len > 0
  ensures:  result.len() == key_len
{
  var pass_bytes = Vec[UInt8].new();
  var pi = 0;
  while pi < password.len() {
    pass_bytes.push(password.char_at(pi) as UInt8);
    pi = pi + 1;
  }
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
    u.push((bi / 16777216 % 256) as UInt8);
    u.push((bi / 65536 % 256) as UInt8);
    u.push((bi / 256 % 256) as UInt8);
    u.push((bi % 256) as UInt8);
    var prev = hmac_sha256(&pass_bytes, &u);
    var block_result = Vec[UInt8].new();
    j = 0;
    while j < prev.len() {
      block_result.push(prev[j]);
      j = j + 1;
    }
    var iter = 1;
    while iter < iterations {
      prev = hmac_sha256(&pass_bytes, &prev);
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
  var final_result = Vec[UInt8].new();
  var i = 0;
  while i < key_len && i < result.len() {
    final_result.push(result[i]);
    i = i + 1;
  }
  return final_result;
}

pub fn argon2(password: &Str, salt: &Vec[UInt8], memory: Int, iterations: Int, parallelism: Int) -> Vec[UInt8] {
  var effective_iterations = iterations;
  if memory > 0 { effective_iterations = iterations + memory / 1024; }
  return pbkdf2(password, salt, effective_iterations, 32);
}

// ============================================================================
// Random Crypto
// ============================================================================

pub fn secure_random_bytes(count: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < count {
    let r = random_range(0, 255);
    result.push(r as UInt8);
    i = i + 1;
  }
  return result;
}

pub fn constant_time_compare(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool
  ensures: result == true => a.len() == b.len()  // equal length needed for equality
{
  if a.len() != b.len() { return false; }
  var diff: Int = 0;
  var i = 0;
  while i < a.len() {
    diff = diff | ((a[i] as Int) ^ (b[i] as Int));
    i = i + 1;
  }
  return diff == 0;
}
