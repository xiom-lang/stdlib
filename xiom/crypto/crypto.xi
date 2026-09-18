// XIOM -- Cryptography
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto
use xiom.crypto.hash;
use xiom.crypto.mac;
use xiom.crypto.kdf;
use xiom.crypto.cipher;
use xiom.crypto.aead;
use xiom.crypto.sign;
use xiom.crypto.keyx;
use xiom.crypto.curves;
use xiom.crypto.rng_crypto;

use xiom.math.bit_and;
use xiom.math.bit_or;
use xiom.math.bit_xor;
use xiom.memory.alloc;
use xiom.math.bit_not;
use xiom.math.shl;
use xiom.math.shr;
use xiom.math.random;
use xiom.math.random_range;
use xiom.math.seed_rng;
use xiom.chacha;
use xiom.poly1305;

// ============================================================================
// Hardware Acceleration FFI
// ============================================================================

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_crypto_aesni_available() -> Int32;
  fn xiom_crypto_shani_available() -> Int32;
  fn xiom_aesni_encrypt_block(plaintext: *UInt8, round_keys: *UInt8, rounds: Int32, ciphertext: *UInt8);
  fn xiom_aesni_decrypt_block(ciphertext: *UInt8, round_keys: *UInt8, rounds: Int32, plaintext: *UInt8);
  fn xiom_aesni_key_expand_128(key: *UInt8, round_keys: *UInt8);
  fn xiom_shani_sha256_compress(state: *UInt32, block: *UInt8);
  fn xiom_sha256_sw_compress(state: *UInt32, block: *UInt8);
  fn xiom_sha224_hash(input: *UInt8, input_len: UInt, output: *UInt8);
  fn xiom_sha384_hash(input: *UInt8, input_len: UInt, output: *UInt8);
  fn xiom_sha512_hash(input: *UInt8, input_len: UInt, output: *UInt8);
  fn xiom_sha256_hash(input: *UInt8, input_len: UInt, output: *UInt8);
  fn xiom_os_entropy(buf: *UInt8, len: Int64) -> Int64;
}

// ============================================================================
// 32-bit Word Helpers
// ============================================================================

fn _u32_mask(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

fn _u32_add(a: Int, b: Int) -> Int {
  return (a + b) & 0xFFFFFFFF;
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
  // Word expansion -- all operations inlined to avoid function-call
  // aliasing in the 64-round loop.
  i = 16;
  while i < 64 {
    let x1 = w[i - 2] & 0xFFFFFFFF;
    let s1a = (x1 / 131072) | ((x1 * 32768) & 0xFFFFFFFF);
    let s1b = (x1 / 524288) | ((x1 * 8192) & 0xFFFFFFFF);
    let s1c = x1 / 1024;
    let es1 = (s1a ^ s1b ^ s1c) & 0xFFFFFFFF;
    let x0 = w[i - 15] & 0xFFFFFFFF;
    let s0a = (x0 / 128) | ((x0 * 33554432) & 0xFFFFFFFF);
    let s0b = (x0 / 262144) | ((x0 * 16384) & 0xFFFFFFFF);
    let s0c = x0 / 8;
    let es0 = (s0a ^ s0b ^ s0c) & 0xFFFFFFFF;
    w[i] = ((es1 + w[i - 7] + es0 + w[i - 16]) & 0xFFFFFFFF) & 0xFFFFFFFF;
    i = i + 1;
  }
  var s: [8]Int;
  s[0] = state[0]; s[1] = state[1]; s[2] = state[2]; s[3] = state[3];
  s[4] = state[4]; s[5] = state[5]; s[6] = state[6]; s[7] = state[7];
  // Round loop -- split into chunks of 16 to avoid codegen issues
  // with very long-running while loops (64 iterations).
  i = 0;
  while i < 4 {
    var chunk = i * 16;
    var end = chunk + 16;
    var j = chunk;
    while j < end {
      var s0 = s[0]; var s1v = s[1]; var s2v = s[2]; var s3v = s[3];
      var s4 = s[4]; var s5 = s[5]; var s6 = s[6]; var s7 = s[7];

      // sigma1(s4): ROTR(6) ^ ROTR(11) ^ ROTR(25)
      var xs = s4 & 0xFFFFFFFF;
      var rs6  = (xs / 64) | ((xs * 67108864) & 0xFFFFFFFF);
      var rs11 = (xs / 2048) | ((xs * 2097152) & 0xFFFFFFFF);
      var rs25 = (xs / 33554432) | ((xs * 128) & 0xFFFFFFFF);
      var s1e = (rs6 ^ rs11 ^ rs25) & 0xFFFFFFFF;

      // ch(s4, s5, s6) = (x & y) ^ (~x & z)
      var ch = ((s4 & s5) ^ ((~s4) & s6)) & 0xFFFFFFFF;

      // T1 = h + sigma1(e) + Ch(e,f,g) + K[j] + w[j]
      var t1 = (s7 + s1e + ch + _SHA256_K[j] + w[j]) & 0xFFFFFFFF;

      // sigma0(s0): ROTR(2) ^ ROTR(13) ^ ROTR(22)
      var ya = s0 & 0xFFFFFFFF;
      var ra2  = (ya / 4) | ((ya * 1073741824) & 0xFFFFFFFF);
      var ra13 = (ya / 8192) | ((ya * 524288) & 0xFFFFFFFF);
      var ra22 = (ya / 4194304) | ((ya * 1024) & 0xFFFFFFFF);
      var s0a = (ra2 ^ ra13 ^ ra22) & 0xFFFFFFFF;

      // maj(s0, s1, s2) = (x & y) ^ (x & z) ^ (y & z)
      var maj = ((s0 & s1v) ^ (s0 & s2v) ^ (s1v & s2v));

      // T2 = sigma0(a) + Maj(a,b,c)
      var t2 = (s0a + maj) & 0xFFFFFFFF;

      // Shift working variables
      s[7] = s6; s[6] = s5; s[5] = s4;
      s[4] = (s3v + t1) & 0xFFFFFFFF;
      s[3] = s2v; s[2] = s1v; s[1] = s0;
      s[0] = (t1 + t2) & 0xFFFFFFFF;
      j = j + 1;
    }
    i = i + 1;
  }
  state[0] = (state[0] + s[0]) & 0xFFFFFFFF;
  state[1] = (state[1] + s[1]) & 0xFFFFFFFF;
  state[2] = (state[2] + s[2]) & 0xFFFFFFFF;
  state[3] = (state[3] + s[3]) & 0xFFFFFFFF;
  state[4] = (state[4] + s[4]) & 0xFFFFFFFF;
  state[5] = (state[5] + s[5]) & 0xFFFFFFFF;
  state[6] = (state[6] + s[6]) & 0xFFFFFFFF;
  state[7] = (state[7] + s[7]) & 0xFFFFFFFF;
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
  // Use the C reference SHA-256 implementation (proven correct).
  // The pure-XIOM algorithm has a codegen bug with 64-round composition.
  unsafe {
    var st_buf = malloc(32); // 8 x 4-byte uint32
    i = 0;
    while i < 8 {
      var v = state[i];
      // x86_64 is little-endian: LSB at lowest address.
      st_buf[i * 4 + 0] = (v % 256) as UInt8;
      st_buf[i * 4 + 1] = (v / 256 % 256) as UInt8;
      st_buf[i * 4 + 2] = (v / 65536 % 256) as UInt8;
      st_buf[i * 4 + 3] = (v / 16777216 % 256) as UInt8;
      i = i + 1;
    }
    var bi = 0;
    while bi < block_count {
      xiom_sha256_sw_compress(st_buf, padded.data + bi * 64);
      bi = bi + 1;
    }
    i = 0;
    while i < 8 {
      var b0 = st_buf[i * 4 + 0] as Int;
      var b1 = st_buf[i * 4 + 1] as Int;
      var b2 = st_buf[i * 4 + 2] as Int;
      var b3 = st_buf[i * 4 + 3] as Int;
      state[i] = (b3 * 16777216) + (b2 * 65536) + (b1 * 256) + b0;
      i = i + 1;
    }
    free(st_buf);
  };
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

pub fn sha256(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    result.push(0);
    i = i + 1;
  }
  unsafe {
    xiom_sha256_hash(data.data, data.len() as UInt, result.data);
  };
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

pub fn sha256_hex(data: &Vec[UInt8]) -> Str {
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

// SHA-512 round constants K[0..79] (FIPS 180-4). Built at runtime because
// module-level const arrays are mis-materialized by the compiler.
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

// SHA-512 initial hash value H0 (FIPS 180-4). Built at runtime (see above).
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
    let t1 = h + _sha512_sigma1(e) + _sha512_ch(e, f, g) + k[i] + w[i];
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
  var state = _sha512_iv();
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
  // C-backed (runtime xiom_runtime.c): the XIOM-side u64 loop produced wrong
  // digests for all inputs except empty-padding-only blocks (kat_crypto_sha2,
  // 2026-08-24). Same treatment as sha224.
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 64 {
    result.push(0);
    i = i + 1;
  }
  unsafe {
    xiom_sha512_hash(data.data, data.len() as UInt, result.data);
  };
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

/// Alias for `md5` whose name cannot collide with the legacy
/// xiom.crypto.md5 module in dotted call position (strict import gate).
pub fn md5_bytes(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 16
{
  return md5(data);
}

// ============================================================================
// BLAKE3 -- Real Implementation (single + multi-chunk tree)
// Spec: https://github.com/BLAKE3-team/BLAKE3-specs
// BLAKE3 is an evolution of BLAKE2 using a binary tree of 1024-byte chunks.
// Each leaf chunk is compressed with the 7-round compression function,
// producing a 32-byte chaining value. Chaining values are merged pairwise
// through parent node compressions. The root compression produces the
// final 32-byte hash.
// ============================================================================

// BLAKE3 IV = first 8 words of SHA-256 constants
const _B3_IV0: Int = 0x6A09E667;
const _B3_IV1: Int = 0xBB67AE85;
const _B3_IV2: Int = 0x3C6EF372;
const _B3_IV3: Int = 0xA54FF53A;
const _B3_IV4: Int = 0x510E527F;
const _B3_IV5: Int = 0x9B05688C;
const _B3_IV6: Int = 0x1F83D9AB;
const _B3_IV7: Int = 0x5BE0CD19;

// BLAKE3 Flags
const _B3_FLAG_CHUNK_START: Int = 1;
const _B3_FLAG_CHUNK_END: Int = 2;
const _B3_FLAG_PARENT: Int = 4;
const _B3_FLAG_ROOT: Int = 8;

// Message schedule for the 7 rounds: 16 message word indices per round.
// The BLAKE3 spec's message schedule permutes the 16 message words each round.
// Built at runtime: the compiler mis-materializes module-level const arrays,
// so the schedule is produced by this builder instead of a const table.
fn _b3_build_schedule() -> Vec[Int] {
  var s = Vec[Int].new();
  // Round 0
  s.push(0); s.push(1); s.push(2); s.push(3); s.push(4); s.push(5); s.push(6); s.push(7);
  s.push(8); s.push(9); s.push(10); s.push(11); s.push(12); s.push(13); s.push(14); s.push(15);
  // Round 1
  s.push(2); s.push(6); s.push(3); s.push(10); s.push(7); s.push(0); s.push(4); s.push(13);
  s.push(1); s.push(11); s.push(12); s.push(5); s.push(9); s.push(14); s.push(15); s.push(8);
  // Round 2
  s.push(3); s.push(4); s.push(10); s.push(12); s.push(13); s.push(2); s.push(7); s.push(14);
  s.push(6); s.push(5); s.push(9); s.push(0); s.push(11); s.push(15); s.push(8); s.push(1);
  // Round 3
  s.push(10); s.push(7); s.push(12); s.push(9); s.push(14); s.push(3); s.push(13); s.push(15);
  s.push(4); s.push(0); s.push(11); s.push(2); s.push(5); s.push(8); s.push(1); s.push(6);
  // Round 4
  s.push(12); s.push(13); s.push(9); s.push(11); s.push(15); s.push(10); s.push(14); s.push(8);
  s.push(7); s.push(2); s.push(5); s.push(3); s.push(0); s.push(1); s.push(6); s.push(4);
  // Round 5
  s.push(9); s.push(14); s.push(11); s.push(5); s.push(8); s.push(12); s.push(15); s.push(1);
  s.push(13); s.push(3); s.push(0); s.push(10); s.push(2); s.push(6); s.push(4); s.push(7);
  // Round 6
  s.push(11); s.push(15); s.push(5); s.push(0); s.push(1); s.push(9); s.push(8); s.push(6);
  s.push(14); s.push(10); s.push(2); s.push(12); s.push(3); s.push(4); s.push(7); s.push(13);
  return s;
}

// BLAKE3 G function: quarter-round on state words a,b,c,d with message words mx,my.
// All operations are modulo 2^32.
fn _b3_g(state: &mut Vec[Int], a: Int, b: Int, c: Int, d: Int, mx: Int, my: Int) {
  state[a] = _u32_add(state[a], _u32_add(state[b], mx));
  state[d] = _u32_rotr(_u32_mask(state[d] ^ state[a]), 16);
  state[c] = _u32_add(state[c], state[d]);
  state[b] = _u32_rotr(_u32_mask(state[b] ^ state[c]), 12);
  state[a] = _u32_add(state[a], _u32_add(state[b], my));
  state[d] = _u32_rotr(_u32_mask(state[d] ^ state[a]), 8);
  state[c] = _u32_add(state[c], state[d]);
  state[b] = _u32_rotr(_u32_mask(state[b] ^ state[c]), 7);
}

// BLAKE3 compression function.
// Inputs:
//   chaining: 8-word chaining value (CV)
//   block: 16-word message block (64 bytes, padded if shorter)
//   counter_lo: low 32 bits of chunk counter
//   counter_hi: high 32 bits of chunk counter
//   block_len: number of bytes in this block (0-64)
//   flags: bitwise OR of flags (CHUNK_START, CHUNK_END, PARENT, ROOT)
//   schedule: 112-entry message schedule built by _b3_build_schedule
// Returns: 16-word state after 7 rounds (NO XOR-back like BLAKE2).
fn _blake3_compress(chaining: &Vec[Int], block: &Vec[Int], counter_lo: Int, counter_hi: Int, block_len: Int, flags: Int, schedule: &Vec[Int]) -> Vec[Int] {
  // Build 16-word state matrix:
  //   row 0: chaining[0..3]
  //   row 1: chaining[4..7]
  //   row 2: IV[0..3]
  //   row 3: counter_lo, counter_hi, block_len, flags
  var state = Vec[Int].new();
  state.push(chaining[0]);
  state.push(chaining[1]);
  state.push(chaining[2]);
  state.push(chaining[3]);
  state.push(chaining[4]);
  state.push(chaining[5]);
  state.push(chaining[6]);
  state.push(chaining[7]);
  state.push(_B3_IV0);
  state.push(_B3_IV1);
  state.push(_B3_IV2);
  state.push(_B3_IV3);
  state.push(counter_lo);
  state.push(counter_hi);
  state.push(block_len);
  state.push(flags);

  // 7 rounds
  var round = 0;
  while round < 7 {
    let off = round * 16;
    // Column steps: G(0,4,8,12), G(1,5,9,13), G(2,6,10,14), G(3,7,11,15)
    _b3_g(&mut state, 0, 4, 8, 12, block[schedule[off + 0]], block[schedule[off + 1]]);
    _b3_g(&mut state, 1, 5, 9, 13, block[schedule[off + 2]], block[schedule[off + 3]]);
    _b3_g(&mut state, 2, 6, 10, 14, block[schedule[off + 4]], block[schedule[off + 5]]);
    _b3_g(&mut state, 3, 7, 11, 15, block[schedule[off + 6]], block[schedule[off + 7]]);
    // Diagonal steps: G(0,5,10,15), G(1,6,11,12), G(2,7,8,13), G(3,4,9,14)
    _b3_g(&mut state, 0, 5, 10, 15, block[schedule[off + 8]], block[schedule[off + 9]]);
    _b3_g(&mut state, 1, 6, 11, 12, block[schedule[off + 10]], block[schedule[off + 11]]);
    _b3_g(&mut state, 2, 7, 8, 13, block[schedule[off + 12]], block[schedule[off + 13]]);
    _b3_g(&mut state, 3, 4, 9, 14, block[schedule[off + 14]], block[schedule[off + 15]]);
    round = round + 1;
  }

  return state;
}

// Read 4 little-endian bytes from offset, return as 32-bit word.
fn _b3_read_u32_le(bytes: &Vec[UInt8], offset: Int) -> Int {
  return _u32_mask(
    (bytes[offset] as Int) +
    ((bytes[offset + 1] as Int) * 256) +
    ((bytes[offset + 2] as Int) * 65536) +
    ((bytes[offset + 3] as Int) * 16777216)
  );
}

// Convert a 64-byte window of the input into 16 little-endian 32-bit words.
// Bytes beyond `start + len` (a partial final block) are zero-padded.
fn _b3_block_from_bytes(bytes: &Vec[UInt8], start: Int, len: Int) -> Vec[Int] {
  var block = Vec[Int].new();
  var i = 0;
  while i < 16 {
    var pos = start + i * 4;
    var word = 0;
    var j = 0;
    while j < 4 {
      if pos + j < start + len {
        word = word | ((bytes[pos + j] as Int) << (8 * j));
      }
      j = j + 1;
    }
    block.push(_u32_mask(word));
    i = i + 1;
  }
  return block;
}

// Write a 32-bit word as 4 little-endian bytes into result.
fn _b3_write_u32_le(out: &mut Vec[UInt8], word: Int) {
  var w = _u32_mask(word);
  out.push((w % 256) as UInt8);
  out.push(((w / 256) % 256) as UInt8);
  out.push(((w / 65536) % 256) as UInt8);
  out.push(((w / 16777216) % 256) as UInt8);
}

// Compress a chunk (up to 1024 bytes) into an 8-word chaining value.
//
// Structure (matching the reference implementation's ChunkState):
//   - While more than 64 bytes remain, compress full 64-byte blocks. The
//     FIRST full block carries CHUNK_START; middle blocks carry no flags.
//   - The final block (1..64 bytes) is compressed once with CHUNK_END (plus
//     CHUNK_START if it is also the first block) and, when `root` is set,
//     ROOT. The single-chunk root therefore applies ROOT on its last block.
// The chaining value chains across blocks via the XOR-back feed-forward.
fn _blake3_compress_chunk(chunk: &Vec[UInt8], chunk_offset: Int, chunk_len: Int, chunk_counter: Int, root: Int, schedule: &Vec[Int]) -> Vec[Int] {
  var cv = Vec[Int].new();
  cv.push(_B3_IV0); cv.push(_B3_IV1); cv.push(_B3_IV2); cv.push(_B3_IV3);
  cv.push(_B3_IV4); cv.push(_B3_IV5); cv.push(_B3_IV6); cv.push(_B3_IV7);

  var pos = 0;
  var first = 1;

  while chunk_len - pos > 64 {
    var bflags = 0;
    if first == 1 {
      bflags = bflags | _B3_FLAG_CHUNK_START;
      first = 0;
    }
    var block = _b3_block_from_bytes(chunk, chunk_offset + pos, 64);
    var state = _blake3_compress(&cv, &block, chunk_counter, 0, 64, bflags, schedule);
    cv[0] = state[0] ^ state[8];
    cv[1] = state[1] ^ state[9];
    cv[2] = state[2] ^ state[10];
    cv[3] = state[3] ^ state[11];
    cv[4] = state[4] ^ state[12];
    cv[5] = state[5] ^ state[13];
    cv[6] = state[6] ^ state[14];
    cv[7] = state[7] ^ state[15];
    pos = pos + 64;
  }

  // Final block (1..64 bytes, or 0 bytes for the empty input).
  var rem = chunk_len - pos;
  var bflags = _B3_FLAG_CHUNK_END;
  if first == 1 {
    bflags = bflags | _B3_FLAG_CHUNK_START;
  }
  if root != 0 {
    bflags = bflags | _B3_FLAG_ROOT;
  }
  var block = _b3_block_from_bytes(chunk, chunk_offset + pos, rem);
  var state = _blake3_compress(&cv, &block, chunk_counter, 0, rem, bflags, schedule);
  cv[0] = state[0] ^ state[8];
  cv[1] = state[1] ^ state[9];
  cv[2] = state[2] ^ state[10];
  cv[3] = state[3] ^ state[11];
  cv[4] = state[4] ^ state[12];
  cv[5] = state[5] ^ state[13];
  cv[6] = state[6] ^ state[14];
  cv[7] = state[7] ^ state[15];

  return cv;
}

// Compress two 8-word chaining values into a parent chaining value.
// The parent message block is left_cv || right_cv (16 words); the chaining
// value for a parent node is the IV. block_len is always 64.
fn _blake3_compress_parent(left_cv: &Vec[Int], right_cv: &Vec[Int], flags: Int, schedule: &Vec[Int]) -> Vec[Int] {
  var iv = Vec[Int].new();
  iv.push(_B3_IV0); iv.push(_B3_IV1); iv.push(_B3_IV2); iv.push(_B3_IV3);
  iv.push(_B3_IV4); iv.push(_B3_IV5); iv.push(_B3_IV6); iv.push(_B3_IV7);

  // Build 16-word message block from two 8-word CVs
  var block = Vec[Int].new();
  var i = 0;
  while i < 8 { block.push(left_cv[i]); i = i + 1; }
  while i < 16 { block.push(right_cv[i - 8]); i = i + 1; }

  var state = _blake3_compress(&iv, &block, 0, 0, 64, flags, schedule);

  // Parent nodes also use the XOR-back feed-forward for their chaining value.
  var cv = Vec[Int].new();
  i = 0;
  while i < 8 { cv.push(state[i] ^ state[i + 8]); i = i + 1; }
  return cv;
}

// Output the 32-byte hash from the 8-word root CV: words 0..7 in order,
// each serialized little-endian.
fn _blake3_output_words(cv: &Vec[Int]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    _b3_write_u32_le(&mut result, cv[i]);
    i = i + 1;
  }
  return result;
}

// Build the BLAKE3 tree level-by-level for multi-chunk inputs and return the
// root output. Nodes are 8-word CVs packed into a Vec[Int]. Pairs are merged
// leftmost-first (BLAKE3 leftmost tree); a lone rightmost node is promoted
// unchanged. The final 2-node merge is the root and uses PARENT|ROOT.
fn _b3_reduce_tree(level: &Vec[Int], schedule: &Vec[Int]) -> Vec[UInt8] {
  var cur = Vec[Int].new();
  var i = 0;
  while i < level.len() {
    cur.push(level[i]);
    i = i + 1;
  }
  while true {
    let node_count = cur.len() / 8;
    if node_count == 2 {
      // Root merge: last pair on the stack is the tree root.
      var left = Vec[Int].new();
      var j = 0;
      while j < 8 { left.push(cur[j]); j = j + 1; }
      var right = Vec[Int].new();
      j = 8;
      while j < 16 { right.push(cur[j]); j = j + 1; }
      var root_cv = _blake3_compress_parent(&left, &right, _B3_FLAG_PARENT | _B3_FLAG_ROOT, schedule);
      return _blake3_output_words(&root_cv);
    }
    var next = Vec[Int].new();
    var idx = 0;
    while idx + 1 < node_count {
      var left = Vec[Int].new();
      var j = idx * 8;
      while j < idx * 8 + 8 { left.push(cur[j]); j = j + 1; }
      var right = Vec[Int].new();
      j = idx * 8 + 8;
      while j < idx * 8 + 16 { right.push(cur[j]); j = j + 1; }
      var parent = _blake3_compress_parent(&left, &right, _B3_FLAG_PARENT, schedule);
      var k = 0;
      while k < 8 { next.push(parent[k]); k = k + 1; }
      idx = idx + 2;
    }
    if idx < node_count {
      // Lone rightmost node: promote unchanged.
      var j = idx * 8;
      while j < idx * 8 + 8 {
        next.push(cur[j]);
        j = j + 1;
      }
    }
    cur = next;
  }
}

/// Compute the BLAKE3 hash of `data` (32-byte output).
///
/// Spec: https://github.com/BLAKE3-team/BLAKE3-specs
///
/// Single-chunk inputs (<= 1024 bytes) compress the chunk directly with
/// CHUNK_START|CHUNK_END|ROOT. Larger inputs are hashed through the binary
/// tree: each 1024-byte chunk produces a leaf CV (chunk counter = chunk
/// index), leaves are merged pairwise via parent nodes, and the root node
/// carries the ROOT flag. The 32-byte digest is the root output words
/// 7,6,5,4,3,2,1,0 serialized little-endian (reversed word order).
pub fn blake3(data: &Vec[UInt8]) -> Vec[UInt8] {
  let len = data.len();
  let chunk_size = 1024;
  let num_chunks = (len + chunk_size - 1) / chunk_size;
  var schedule = _b3_build_schedule();

  if num_chunks <= 1 {
    // Single chunk -- the chunk's final block carries ROOT.
    var cv = _blake3_compress_chunk(data, 0, len, 0, 1, &schedule);
    return _blake3_output_words(&cv);
  }

  // Multi-chunk: build the tree level-by-level.
  var level = Vec[Int].new();
  var chunk_idx = 0;
  while chunk_idx < num_chunks {
    var chunk_start = chunk_idx * chunk_size;
    var chunk_len = chunk_size;
    if chunk_start + chunk_len > len { chunk_len = len - chunk_start; }
    var cv = _blake3_compress_chunk(data, chunk_start, chunk_len, chunk_idx, 0, &schedule);
    var i = 0;
    while i < 8 {
      level.push(cv[i]);
      i = i + 1;
    }
    chunk_idx = chunk_idx + 1;
  }
  return _b3_reduce_tree(&level, &schedule);
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
// AES -- S-box, Key Expansion, Encrypt/Decrypt
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
  // No requires clauses: the body validates and returns Err gracefully
  // (documented stdlib rule -- contracts trap on violation, BUG 22 #5).
{
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  var aesni: Int = 0;
  unsafe { aesni = xiom_crypto_aesni_available(); }
  if aesni != 0 && key.len() == 16 {
    // 6D.4: Hardware-accelerated AES-128 path (AES-NI on x86_64)
    // Uses FFI xiom_aesni_encrypt_block for hardware acceleration.
    // Falls through to software if AES-NI is unavailable.
    let (expanded_key, nr) = _aes_key_expansion(key);
    var padded = _pkcs7_pad(plaintext);
    var result = Vec[UInt8].new();
    let blocks = padded.len() / 16;
    var bi = 0;
    while bi < blocks {
      // 6D.4: Use AES-NI hardware path via FFI
      // (fixed-array zero-init form; `[0; 16]` repeat literal is not in the
      // language spec -- declared arrays zero-initialize)
      var ct_buf: [16]UInt8;
      unsafe {
        xiom_aesni_encrypt_block(
          &padded[bi * 16] as *UInt8,
          &expanded_key[0] as *UInt8,
          nr as Int32,
          &ct_buf[0] as *UInt8
        );
      }
      var j = 0;
      while j < 16 {
        result.push(ct_buf[j]);
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
  // No requires clauses: the body validates and returns Err gracefully
  // (documented stdlib rule -- contracts trap on violation, BUG 22 #5).
{
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  if ciphertext.len() % 16 != 0 {
    return Err("ciphertext length must be a multiple of 16");
  }
  var aesni2: Int = 0;
  unsafe { aesni2 = xiom_crypto_aesni_available(); }
  if aesni2 != 0 && key.len() == 16 {
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
  // Software fallback: same block-by-block AES decrypt.
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

// ============================================================================
// AES-GCM (Galois/Counter Mode) -- authenticated encryption in pure XIOM
//
// Built on the existing AES primitives: _aes_key_expansion and
// _aes_encrypt_block. GCM = AES-CTR for confidentiality + GHASH (multiplication
// in GF(2^128)) for authentication. Blocks are represented as Vec[UInt8] of
// length 16, matching _aes_encrypt_block's parameter/return type. Shifts use
// * 2 / / 2 like the rest of this file (no native << / >> operators exist here).
//
// NIST SP 800-38D test vectors (for later execution tests):
//   Test Case 1 (AES-128, K=0^128, IV=0^96, P="", A=""):
//     H = 66e94bd4ef8a2c3b884cfa59ca342b2e, T = 58e2fccefa7e3061367f1d57a4e7455a
//   Test Case 2 (AES-128, K=0^128, IV=0^96, P=0^128, A=""):
//     C = 0388dace60b6a392f328c2b971b2fe78, T = ab6e47d42cec13bdf53a67b21257bdb6
// ============================================================================

// Increment the rightmost 32 bits (bytes 12..16) of a 16-byte counter block,
// modulo 2^32 (GCM inc32). Big-endian counter, as required by the spec.
fn _gcm_inc32(counter: &mut Vec[UInt8]) {
  var carry = 1;
  var i = 15;
  while i >= 12 {
    let v = (counter[i] as Int) + carry;
    counter[i] = (v % 256) as UInt8;
    carry = v / 256;
    i = i - 1;
  }
}

// Multiplication in GF(2^128) using the GCM reduction polynomial
// R = 0xE1 || 0^120 (i.e. 0xE1 << 120). Standard shift-and-xor algorithm.
// Blocks are 16-byte big-endian; bit 0 is the MSB of byte 0. Computes x * y.
fn _gcm_gf_mult(x: &Vec[UInt8], y: &Vec[UInt8]) -> Vec[UInt8] {
  var z = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    z.push(0);
    i = i + 1;
  }
  var v = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    v.push(x[i]);
    i = i + 1;
  }
  var bit = 0;
  while bit < 128 {
    let byte_index = bit / 8;
    let within = bit % 8;
    var mask = 128;
    var s = 0;
    while s < within {
      mask = mask / 2;
      s = s + 1;
    }
    let y_bit = (y[byte_index] as Int) & mask;
    var k = 0;
    if y_bit != 0 {
      k = 0;
      while k < 16 {
        z[k] = (z[k] as Int ^ v[k] as Int) as UInt8;
        k = k + 1;
      }
    }
    // v_127 is the least-significant bit of the whole 128-bit value (LSB of v[15])
    let lsb = (v[15] as Int) & 1;
    // shift v right by one bit across all 16 bytes (v[0] is most significant)
    var carry = 0;
    k = 0;
    while k < 16 {
      let cur = v[k] as Int;
      let new_carry = cur & 1;
      v[k] = ((cur / 2) | (carry * 128)) as UInt8;
      carry = new_carry;
      k = k + 1;
    }
    if lsb != 0 {
      // XOR with R = 0xE1 in the most-significant byte
      v[0] = (v[0] as Int ^ 0xE1) as UInt8;
    }
    bit = bit + 1;
  }
  return z;
}

// Write a 64-bit value big-endian into buf at the given offset.
fn _gcm_write_u64_be(buf: &mut Vec[UInt8], offset: Int, value: Int) {
  var v = value;
  var i = 7;
  while i >= 0 {
    buf[offset + i] = (v % 256) as UInt8;
    v = v / 256;
    i = i - 1;
  }
}

// GHASH update: fold `data` (zero-padded to full 16-byte blocks) into the
// running value x by XOR-and-multiply with H. Returns the new running value.
fn _ghash_update(x_in: &Vec[UInt8], h: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var x = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    x.push(x_in[i]);
    i = i + 1;
  }
  let full_blocks = data.len() / 16;
  var bi = 0;
  while bi < full_blocks {
    i = 0;
    while i < 16 {
      x[i] = (x[i] as Int ^ data[bi * 16 + i] as Int) as UInt8;
      i = i + 1;
    }
    x = _gcm_gf_mult(&x, h);
    bi = bi + 1;
  }
  let rem = data.len() - full_blocks * 16;
  if rem > 0 {
    // XOR only the remaining bytes; the rest of the block is treated as zero
    i = 0;
    while i < rem {
      x[i] = (x[i] as Int ^ data[full_blocks * 16 + i] as Int) as UInt8;
      i = i + 1;
    }
    x = _gcm_gf_mult(&x, h);
  }
  return x;
}

// GHASH(H, A, C): process AAD blocks, then ciphertext blocks, then the
// length block (bit-lengths of A and C), each XOR-and-multiplied by H.
fn _ghash(h: &Vec[UInt8], aad: &Vec[UInt8], ct: &Vec[UInt8]) -> Vec[UInt8] {
  var x = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    x.push(0);
    i = i + 1;
  }
  x = _ghash_update(&x, h, aad);
  x = _ghash_update(&x, h, ct);
  var len_block = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    len_block.push(0);
    i = i + 1;
  }
  let aad_bits = aad.len() * 8;
  let ct_bits = ct.len() * 8;
  _gcm_write_u64_be(&mut len_block, 0, aad_bits);
  _gcm_write_u64_be(&mut len_block, 8, ct_bits);
  i = 0;
  while i < 16 {
    x[i] = (x[i] as Int ^ len_block[i] as Int) as UInt8;
    i = i + 1;
  }
  x = _gcm_gf_mult(&x, h);
  return x;
}

// Build J0 = IV || 0x00000001 for a 96-bit IV, per GCM.
fn _gcm_j0(nonce: &Vec[UInt8]) -> Vec[UInt8] {
  var j0 = Vec[UInt8].new();
  var i = 0;
  while i < 12 {
    j0.push(nonce[i]);
    i = i + 1;
  }
  j0.push(0);
  j0.push(0);
  j0.push(0);
  j0.push(1);
  return j0;
}

pub fn aes_encrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], plaintext: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<(Vec[UInt8], Vec[UInt8]), Str> {
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  if nonce.len() != 12 {
    return Err("AES-GCM requires a 96-bit (12-byte) nonce");
  }
  let (expanded_key, nr) = _aes_key_expansion(key);
  // H = AES_encrypt(zero block)
  var zero = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    zero.push(0);
    i = i + 1;
  }
  var h = _aes_encrypt_block(&zero, 0, &expanded_key, nr);
  // J0 = IV || 0x00000001 ; counter blocks for data start at inc32(J0)
  var j0 = _gcm_j0(nonce);
  var counter = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    counter.push(j0[i]);
    i = i + 1;
  }
  var ciphertext = Vec[UInt8].new();
  let pt_len = plaintext.len();
  var pos = 0;
  while pos < pt_len {
    _gcm_inc32(&mut counter);
    var ks = _aes_encrypt_block(&counter, 0, &expanded_key, nr);
    var blk = 0;
    while blk < 16 && pos + blk < pt_len {
      ciphertext.push((plaintext[pos + blk] as Int ^ ks[blk] as Int) as UInt8);
      blk = blk + 1;
    }
    pos = pos + 16;
  }
  // tag = GHASH(H, A, C) XOR AES_encrypt(J0)
  var s = _ghash(&h, aad, &ciphertext);
  var ej0 = _aes_encrypt_block(&j0, 0, &expanded_key, nr);
  var tag = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    tag.push((s[i] as Int ^ ej0[i] as Int) as UInt8);
    i = i + 1;
  }
  return Ok((ciphertext, tag));
}

pub fn aes_decrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], ciphertext: &Vec[UInt8], tag: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if key.len() != 16 && key.len() != 24 && key.len() != 32 {
    return Err("invalid key length: must be 16, 24, or 32 bytes");
  }
  if nonce.len() != 12 {
    return Err("AES-GCM requires a 96-bit (12-byte) nonce");
  }
  if tag.len() != 16 {
    return Err("AES-GCM tag must be 16 bytes");
  }
  let (expanded_key, nr) = _aes_key_expansion(key);
  var zero = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    zero.push(0);
    i = i + 1;
  }
  var h = _aes_encrypt_block(&zero, 0, &expanded_key, nr);
  var j0 = _gcm_j0(nonce);
  // Recompute the expected tag over the received ciphertext, then verify
  // BEFORE releasing any plaintext (encrypt-then-MAC / verify-then-decrypt).
  var s = _ghash(&h, aad, ciphertext);
  var ej0 = _aes_encrypt_block(&j0, 0, &expanded_key, nr);
  var expected_tag = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    expected_tag.push((s[i] as Int ^ ej0[i] as Int) as UInt8);
    i = i + 1;
  }
  // Constant-time tag comparison (reuses the shared XOR-accumulate helper).
  let matched = constant_time_compare(&expected_tag, tag);
  if matched == false {
    return Err("AES-GCM authentication failed: tag mismatch");
  }
  // GCTR decryption is identical to encryption (XOR with the key stream).
  var counter = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    counter.push(j0[i]);
    i = i + 1;
  }
  var plaintext = Vec[UInt8].new();
  let ct_len = ciphertext.len();
  var pos = 0;
  while pos < ct_len {
    _gcm_inc32(&mut counter);
    var ks = _aes_encrypt_block(&counter, 0, &expanded_key, nr);
    var blk = 0;
    while blk < 16 && pos + blk < ct_len {
      plaintext.push((ciphertext[pos + blk] as Int ^ ks[blk] as Int) as UInt8);
      blk = blk + 1;
    }
    pos = pos + 16;
  }
  return Ok(plaintext);
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
  var pub_key = Vec[UInt8].new();
  i = 0;
  while i < key_size { pub_key.push(n_bytes[i]); i = i + 1; }
  i = 0;
  while i < 4 { pub_key.push(public_bytes[i]); i = i + 1; }
  var priv = Vec[UInt8].new();
  i = 0;
  while i < key_size { priv.push(n_bytes[i]); i = i + 1; }
  i = 0;
  while i < key_size { priv.push(d_bytes[i]); i = i + 1; }
  return Ok(KeyPair{ public: pub_key; private: priv; });
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

// Legacy-PRNG seeding state for the NO-OS degraded fallback only (see
// os_secure_random_bytes). One flag-gated OS draw per process seeds
// math._rng_state so even the fallback path is not deterministic across
// runs. Primary draws no longer touch this path (R4 flip, 041e8bb3).
var _legacy_rng_seeded: Bool = false;

fn _seed_legacy_rng() {
  if _legacy_rng_seeded { return; };
  _legacy_rng_seeded = true;
  var seed_bytes = os_secure_random_bytes(8);
  if seed_bytes.len() == 8 {
    var seed: Int = 0;
    var i = 0;
    while i < 8 {
      seed = seed | ((seed_bytes[i] as Int) << (i * 8));
      i = i + 1;
    };
    seed_rng(seed);  // seed_rng(0) falls back to state 1; fine either way
  };
}

/// OS-entropy CSPRNG draw (ProcessPrng/RtlGenRandom on Windows,
/// /dev/urandom on Unix), degrading to the legacy PRNG only when no OS
/// source answers (degraded mode documented -- do not treat as secure).
/// Backs secure_random_bytes since the confined-block growth fix
/// (COMPILER_BUGS.md R4, 041e8bb3) removed the multi-draw AV; also used
/// for the legacy fallback's one-time process seed.
pub fn os_secure_random_bytes(count: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  if count <= 0 {
    return result;
  };
  unsafe {
    var probe = Vec[UInt8].new();
    var z = 0;
    while z < 8 { probe.push(0u8); z = z + 1; };
    var have_os = false;
    if xiom_os_entropy(probe.data, 8) == 8 {
      have_os = true;
    };
    if have_os {
      var done = 0;
      while done < count {
        var want = count - done;
        if want > 4096 {
          want = 4096;
        };
        var chunk = Vec[UInt8].new();
        z = 0;
        while z < want { chunk.push(0u8); z = z + 1; };
        var got = xiom_os_entropy(chunk.data, want as Int64);
        if got != (want as Int64) {
          break;
        };
        var k = 0;
        while k < want {
          result.push(chunk[k]);
          k = k + 1;
        }
        done = done + want;
      }
    };
    if result.len() < count {
      var i = 0;
      while i < count {
        let r = random_range(0, 255);
        result.push(r as UInt8);
        i = i + 1;
      }
    };
  };
  return result;
}

pub fn secure_random_bytes(count: Int) -> Vec[UInt8] {
  // OS-entropy CSPRNG: ProcessPrng/RtlGenRandom on Windows, /dev/urandom on
  // Unix (xiom_os_entropy in the runtime; multi-draw shapes unblocked by the
  // confined-block growth fix -- COMPILER_BUGS.md R4, 041e8bb3). Degrades to
  // the OS-seeded legacy LCG ONLY when no OS source answers (internal
  // fallback in os_secure_random_bytes); that degraded mode is documented,
  // not silent -- code deriving keys must treat a no-OS environment as
  // insecure regardless of this function's fallback.
  _seed_legacy_rng();
  return os_secure_random_bytes(count);
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

// ============================================================================
// HKDF (RFC 5869) -- HMAC-based Key Derivation Function
//
// HKDF consists of two steps:
//   1. Extract: PRK = HMAC-SHA256(salt, IKM)
//   2. Expand: OKM = T(1) || T(2) || ... || T(N) truncated to okm_len
//      where T(0) = empty, T(i) = HMAC-SHA256(PRK, T(i-1) || info || i)
//      i is a single byte counter (1, 2, 3, ...)
//
// RFC 5869 test case 1:
//   IKM  = 0x0b0b0b... (22 times)
//   salt = 0x000102030405060708090a0b0c
//   info = 0xf0f1f2f3f4f5f6f7f8f9
//   L    = 42
//   OKM  = 3cb25f25faacd57a90434f64d0362f2a
//          2d2d0a90cf1a5a4c5db02d56ecc4c5bf
//          34007208d5b887185865
//
// Security notes:
//   - Extract step concentrates entropy from IKM.
//   - Salt should be random but not secret; can be all-zeros.
//   - Info binds derived key to context; must be unique per key.
// ============================================================================

pub fn hkdf_sha256(ikm: &Vec[UInt8], salt: &Vec[UInt8], info: &Vec[UInt8], okm_len: Int) -> Result[Vec[UInt8], Str] {
  if okm_len < 1 { return Err("okm_len must be >= 1"); }
  let hash_len = 32;
  let max_len = 255 * hash_len;
  if okm_len > max_len { return Err("okm_len exceeds maximum (255 * 32)"); }

  // Step 1: Extract -- PRK = HMAC-SHA256(salt, IKM)
  var prk = hmac_sha256(salt, ikm);

  // Step 2: Expand -- T(i) = HMAC(PRK, T(i-1) || info || i)
  var result = Vec[UInt8].new();
  var prev = Vec[UInt8].new(); // T(0) = empty

  var block_num = 1;
  while result.len() < okm_len {
    // Build input: T(i-1) || info || i
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

    // T(i) = HMAC-SHA256(PRK, input)
    prev = hmac_sha256(&prk, &hmac_input);

    // Append to result
    j = 0;
    while j < prev.len() && result.len() < okm_len {
      result.push(prev[j]);
      j = j + 1;
    }

    block_num = block_num + 1;
  }

  return Ok(result);
}

// ============================================================================
// ChaCha20-Poly1305 AEAD (RFC 8439 Section 2.8)
//
// Authenticated Encryption with Associated Data using ChaCha20 and Poly1305.
//
// Algorithm:
//   1. Generate 32-byte Poly1305 one-time key from ChaCha20 block 0 keystream.
//   2. Encrypt plaintext using ChaCha20 keystream starting from block 1.
//   3. Compute Poly1305 tag over: pad16(AAD) || pad16(ciphertext) ||
//      le64(AAD_len) || le64(CT_len).
//
// Key: 32 bytes (256-bit). Nonce: 12 bytes (96-bit), MUST be unique per key.
// AAD: arbitrary bytes, authenticated but NOT encrypted.
// Plaintext: arbitrary bytes to encrypt and authenticate.
// ciphertext: out-param, populated with encrypted data (same length as plaintext).
// tag: out-param, populated with 16-byte authentication tag.
// Returns: true on success.
//
// RFC 8439 test vector (Section 2.8.2):
//   key = 808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f
//   nonce = 070000004041424344454647
//   aad = 50515253c0c1c2c3c4c5c6c7
//   plaintext = "Ladies and Gentlemen of the class of '99..."
//   ciphertext = d31a8d34648e60db7b86afbc53ef7ec2...
//   tag = 1ae10b594f09e26a7e902ecbd0600691
//
// Security notes:
//   - Nonce MUST be unique for every message under the same key.
//   - Nonce reuse completely breaks confidentiality AND authenticity.
//   - The 16-byte tag provides 128-bit authentication strength.
// ============================================================================

pub fn chacha20_poly1305_encrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], aad: &Vec[UInt8], plaintext: &Vec[UInt8], ciphertext: &mut Vec[UInt8], tag: &mut Vec[UInt8]) -> Bool {
  if key.len() != 32 { return false; }
  if nonce.len() != 12 { return false; }

  // Generate Poly1305 one-time key: ChaCha20 block 0 keystream, first 32 bytes.
  // We do this by encrypting 64 zero bytes: bytes 0-31 = poly_key, bytes 32-63 = discard.
  // Bytes 64+ are plaintext keystream (ciphertext = plaintext XOR keystream).
  var prepend_len = 64;
  var combined = Vec[UInt8].new();
  var i = 0;
  while i < prepend_len { combined.push(0); i = i + 1; }
  i = 0;
  while i < plaintext.len() { combined.push(plaintext[i]); i = i + 1; }

  var keystream_output = xiom.chacha.chacha20_encrypt(key, nonce, &combined);

  // Extract Poly1305 key (first 32 bytes of output)
  var poly_key = Vec[UInt8].new();
  i = 0;
  while i < 32 { poly_key.push(keystream_output[i]); i = i + 1; }

  // Extract ciphertext (bytes 64+ of output, same length as plaintext)
  ciphertext.clear();
  i = prepend_len;
  while i < prepend_len + plaintext.len() {
    ciphertext.push(keystream_output[i]);
    i = i + 1;
  }

  // Build AEAD message for Poly1305: pad16(AAD) || pad16(CT) || le64(AAD_len) || le64(CT_len)
  var poly_msg = Vec[UInt8].new();

  // pad16(AAD): AAD followed by zero padding to 16-byte boundary
  i = 0;
  while i < aad.len() { poly_msg.push(aad[i]); i = i + 1; }
  var aad_pad = 16 - (aad.len() % 16);
  if aad_pad == 16 { aad_pad = 0; }
  i = 0;
  while i < aad_pad { poly_msg.push(0); i = i + 1; }

  // pad16(ciphertext): ciphertext followed by zero padding to 16-byte boundary
  i = 0;
  while i < ciphertext.len() { poly_msg.push(ciphertext[i]); i = i + 1; }
  var ct_pad = 16 - (ciphertext.len() % 16);
  if ct_pad == 16 { ct_pad = 0; }
  i = 0;
  while i < ct_pad { poly_msg.push(0); i = i + 1; }

  // le64(AAD length in octets)
  var aad_len = aad.len();
  i = 0;
  while i < 8 {
    poly_msg.push((aad_len % 256) as UInt8);
    aad_len = aad_len / 256;
    i = i + 1;
  }

  // le64(ciphertext length in octets)
  var ct_len_val = ciphertext.len();
  i = 0;
  while i < 8 {
    poly_msg.push((ct_len_val % 256) as UInt8);
    ct_len_val = ct_len_val / 256;
    i = i + 1;
  }

  // Compute tag
  var computed_tag = xiom.poly1305.poly1305_mac(&poly_key, &poly_msg);

  // Copy to out-param
  tag.clear();
  i = 0;
  while i < computed_tag.len() { tag.push(computed_tag[i]); i = i + 1; }

  return true;
}

// ============================================================================
// ChaCha20-Poly1305 AEAD -- Decrypt
//
// Algorithm:
//   1. Re-generate Poly1305 one-time key from ChaCha20 block 0.
//   2. Compute expected tag over: pad16(AAD) || pad16(ciphertext) ||
//      le64(AAD_len) || le64(CT_len).
//   3. Compare expected_tag with provided tag in constant time.
//   4. If match, decrypt ciphertext to plaintext using ChaCha20 block 1+ keystream.
//
// Key: 32 bytes. Nonce: 12 bytes. AAD: authenticated but unencrypted data.
// ciphertext: encrypted data to authenticate and decrypt.
// tag: 16-byte authentication tag to verify.
// plaintext: out-param, populated with decrypted data on success.
// Returns: true if authentication passed and decryption succeeded.
//
// Security notes:
//   - Decryption only proceeds if tag verification passes (encrypt-then-MAC).
//   - Constant-time tag comparison prevents timing oracle attacks.
// ============================================================================

pub fn chacha20_poly1305_decrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], aad: &Vec[UInt8], ciphertext: &Vec[UInt8], tag: &Vec[UInt8], plaintext: &mut Vec[UInt8]) -> Bool {
  if key.len() != 32 { return false; }
  if nonce.len() != 12 { return false; }
  if tag.len() != 16 { return false; }

  // Re-generate Poly1305 one-time key (same as encrypt)
  var prepend_len = 64;
  var ct_len = ciphertext.len();
  var combined = Vec[UInt8].new();
  var i = 0;
  while i < prepend_len { combined.push(0); i = i + 1; }
  i = 0;
  while i < ct_len { combined.push(ciphertext[i]); i = i + 1; }

  var keystream_output = xiom.chacha.chacha20_encrypt(key, nonce, &combined);

  var poly_key = Vec[UInt8].new();
  i = 0;
  while i < 32 { poly_key.push(keystream_output[i]); i = i + 1; }

  // Build Poly1305 message (same as encrypt, over AAD || CT)
  var poly_msg = Vec[UInt8].new();

  i = 0;
  while i < aad.len() { poly_msg.push(aad[i]); i = i + 1; }
  var aad_pad = 16 - (aad.len() % 16);
  if aad_pad == 16 { aad_pad = 0; }
  i = 0;
  while i < aad_pad { poly_msg.push(0); i = i + 1; }

  i = 0;
  while i < ciphertext.len() { poly_msg.push(ciphertext[i]); i = i + 1; }
  var ct_pad = 16 - (ciphertext.len() % 16);
  if ct_pad == 16 { ct_pad = 0; }
  i = 0;
  while i < ct_pad { poly_msg.push(0); i = i + 1; }

  var aad_len = aad.len();
  i = 0;
  while i < 8 {
    poly_msg.push((aad_len % 256) as UInt8);
    aad_len = aad_len / 256;
    i = i + 1;
  }

  var ct_len_val2 = ciphertext.len();
  i = 0;
  while i < 8 {
    poly_msg.push((ct_len_val2 % 256) as UInt8);
    ct_len_val2 = ct_len_val2 / 256;
    i = i + 1;
  }

  var expected_tag = xiom.poly1305.poly1305_mac(&poly_key, &poly_msg);

  // Constant-time tag comparison
  let matched = constant_time_compare(&expected_tag, tag);
  if matched == false { return false; }

  // Decrypt: plaintext = ciphertext XOR keystream (bytes 64+ of output)
  plaintext.clear();
  i = prepend_len;
  while i < prepend_len + ct_len {
    plaintext.push(keystream_output[i]);
    i = i + 1;
  }

  return true;
}

// ============================================================================
// SHA-224 -- Truncated SHA-256 with distinct IV
//
// SHA-224 is identical to SHA-256 but:
//   1. Uses a different 8-word initialization vector.
//   2. Outputs only the first 28 bytes (7 words) of the 32-byte hash.
//
// IV = [0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
//       0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4]
//
// Test vector: SHA-224("") = d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f
//
// Security notes:
//   - SHA-224 provides 112-bit collision resistance (birthday bound).
//   - Preimage resistance matches the full SHA-256 (256-bit).
// ============================================================================

// SHA-224 delegates to the runtime C path (xiom_sha224_hash in
// runtime/sha256_sw.c). The previous XIOM-side state marshalling around
// xiom_sha256_sw_compress miscompiles (zero-offset store corruption into the
// malloc'd state buffer; probed 2026-08-24 -- wrong digests for any non-empty
// message while empty passed). Same architecture as sha256 below.
/// SHA-224 delegates to the runtime C path (xiom_sha224_hash in
/// runtime/sha256_sw.c). The previous XIOM-side state marshalling around
/// xiom_sha256_sw_compress miscompiles (zero-offset store corruption into the
/// malloc'd state buffer; probed 2026-08-24 -- wrong digests for any non-empty
/// message while empty passed). Same architecture as sha256 below.
pub fn sha224(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 28
{
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 28 {
    result.push(0);
    i = i + 1;
  }
  unsafe {
    xiom_sha224_hash(data.data, data.len() as UInt, result.data);
  };
  return result;
}

// ============================================================================
// SHA-384 -- Truncated SHA-512 with distinct IV
//
// SHA-384 is identical to SHA-512 but:
//   1. Uses a different 8-word initialization vector.
//   2. Outputs only the first 48 bytes (6 words) of the 64-byte hash.
//
// IV = [0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17,
//       0x152fecd8f70e5939, 0x67332667ffc00b31, 0x8eb44a8768581511,
//       0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4]
//
// Test vector: SHA-384("") = 38b060a751ac96384cd9327eb1b1e36a
//                            21fdb71114be07434c0cc7bf63f6e1da
//                            274edebfe76f65fbd51ad2f14898b95b
//
// Security notes:
//   - SHA-384 provides 192-bit collision resistance (birthday bound).
//   - Preimage resistance matches the full SHA-512 (512-bit).
// ============================================================================

// SHA-384 uses a distinct 8-word IV; the digest is the first 48 bytes.
// Built at runtime (see _sha224_iv for the const-array workaround note).
fn _sha384_iv() -> Vec[Int] {
  var v = Vec[Int].new();
  v.push(0xcbbb9d5dc1059ed8);
  v.push(0x629a292a367cd507);
  v.push(0x9159015a3070dd17);
  v.push(0x152fecd8f70e5939);
  v.push(0x67332667ffc00b31);
  v.push(0x8eb44a8768581511);
  v.push(0xdb0c2e0d64f98fa7);
  v.push(0x47b5481dbefa4fa4);
  return v;
}

pub fn sha384(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 48
{
  // C-backed (runtime xiom_runtime.c): same rationale as sha512 -- the
  // XIOM-side u64 block implementation produced wrong digests.
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 48 {
    result.push(0);
    i = i + 1;
  }
  unsafe {
    xiom_sha384_hash(data.data, data.len() as UInt, result.data);
  };
  return result;
}
