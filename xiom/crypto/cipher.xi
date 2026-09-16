// XIOM - Cryptography: Cipher
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.crypto.cipher

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Symmetric ciphers: AES modes (ECB/CBC/CTR/GCM/CFB/OFB), ChaCha20,
// ChaCha20-Poly1305, DES and 3DES.
//
// Delegation:
//   - aes_encrypt_ecb / aes_decrypt_ecb delegate to xiom.crypto.aes_encrypt /
//     aes_decrypt (the flat ECB+PKCS#7 implementation).
//   - chacha20_* delegate to the xiom.chacha module (state counter seeded).
//   - des_* / triple_des_* delegate to the xiom.des module.
//   - aes_encrypt_gcm / aes_decrypt_gcm are implemented locally (their names
//     collide with the flat module's, so same-name delegation would
//     miscompile; BUG 25 #1) and return/accept a combined ciphertext||tag.
//   - CBC/CTR/CFB/OFB are implemented locally on the local AES block
//     primitives.
//
// Security notes:
//   - ECB is provided for interop only: it leaks block equality.
//   - CTR/CFB/OFB/GCM require a unique nonce per key; nonce reuse breaks
//     confidentiality. GCM verifies the tag before releasing plaintext.
//   - DES/3DES are legacy and should not be used for new designs.
// ============================================================================

use xiom.crypto;
use xiom.chacha;
use xiom.poly1305;
use xiom.des;

// ============================================================================
// AES primitives (FIPS 197)
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

fn _gf_mul9(a: UInt8) -> UInt8 {
  return (_gf_mul2(_gf_mul2(_gf_mul2(a))) as Int ^ a as Int) as UInt8;
}

fn _gf_mul11(a: UInt8) -> UInt8 {
  var t = _gf_mul2(_gf_mul2(a));
  return (_gf_mul2(t) as Int ^ t as Int ^ a as Int) as UInt8;
}

fn _gf_mul13(a: UInt8) -> UInt8 {
  var t = _gf_mul2(_gf_mul2(a));
  return (_gf_mul2(t) as Int ^ _gf_mul2(a) as Int ^ a as Int) as UInt8;
}

fn _gf_mul14(a: UInt8) -> UInt8 {
  var t = _gf_mul2(_gf_mul2(a));
  return (_gf_mul2(t) as Int ^ t as Int ^ _gf_mul2(a) as Int) as UInt8;
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

type _AesSchedule = {
  key: Vec[UInt8];
  rounds: Int;
}

fn _aes_key_expansion(key: &Vec[UInt8]) -> _AesSchedule {
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
  return _AesSchedule{ key: expanded; rounds: nr; };
}

fn _aes_valid_key(key: &Vec[UInt8]) -> Bool {
  return key.len() == 16 || key.len() == 24 || key.len() == 32;
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

/// Raw AES block encryption (16 bytes in -> 16 bytes out, no padding/mode).
/// Added as a public primitive so MAC modules (CBC-MAC, CMAC) can reuse the
/// verified block cipher. Returns Err on invalid key length.
/// Complexity: O(1) (fixed 10-14 rounds).
pub fn aes_block_encrypt(key: &Vec[UInt8], block: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) {
    return Err("aes_block_encrypt: invalid key length");
  }
  if block.len() != 16 {
    return Err("aes_block_encrypt: block must be 16 bytes");
  }
  let sched = _aes_key_expansion(key);
  return Ok(_aes_encrypt_block(block, 0, &sched.key, sched.rounds));
}

/// Raw AES block decryption (16 bytes in -> 16 bytes out). See
/// aes_block_encrypt.
/// Complexity: O(1).
pub fn aes_block_decrypt(key: &Vec[UInt8], block: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) {
    return Err("aes_block_decrypt: invalid key length");
  }
  if block.len() != 16 {
    return Err("aes_block_decrypt: block must be 16 bytes");
  }
  let sched = _aes_key_expansion(key);
  return Ok(_aes_decrypt_block(block, 0, &sched.key, sched.rounds));
}

fn _pkcs7_pad(data: &Vec[UInt8]) -> Vec[UInt8] {
  let block_size = 16;
  var pad_val = block_size - (data.len() % block_size);
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
  if data.len() == 0 { return Err("invalid padding: empty data"); }
  if data.len() % 16 != 0 { return Err("invalid padding: length"); }
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

// ============================================================================
// AES modes
// ============================================================================

/// AES-ECB encrypt with PKCS#7 padding. Implemented locally on the verified
/// AES block primitive (the flat module's aes_decrypt miscompiles its length
/// check in the current build, so delegation is unsafe).
/// Complexity: O(n).
pub fn aes_encrypt_ecb(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_encrypt_ecb: invalid key length"); }
  let sched = _aes_key_expansion(key);
  var padded = _pkcs7_pad(data);
  var result = Vec[UInt8].new();
  var bi = 0;
  while bi < padded.len() / 16 {
    var ct = _aes_encrypt_block(&padded, bi * 16, &sched.key, sched.rounds);
    var i = 0;
    while i < 16 {
      result.push(ct[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  return Ok(result);
}

/// AES-ECB decrypt with padding removal. Local implementation (see
/// aes_encrypt_ecb).
/// Complexity: O(n).
pub fn aes_decrypt_ecb(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_decrypt_ecb: invalid key length"); }
  var dlen = data.len();
  var rem = dlen - (dlen / 16) * 16;
  if rem != 0 { return Err("aes_decrypt_ecb: ciphertext length must be a multiple of 16"); }
  let sched = _aes_key_expansion(key);
  var decrypted = Vec[UInt8].new();
  var bi = 0;
  while bi < data.len() / 16 {
    var pt = _aes_decrypt_block(data, bi * 16, &sched.key, sched.rounds);
    var i = 0;
    while i < 16 {
      decrypted.push(pt[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  return _pkcs7_unpad(&decrypted);
}

/// AES-CBC encrypt with PKCS#7 padding.
/// Complexity: O(n).
pub fn aes_encrypt_cbc(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_encrypt_cbc: invalid key length"); }
  if iv.len() != 16 { return Err("aes_encrypt_cbc: IV must be 16 bytes"); }
  let sched = _aes_key_expansion(key);
  var padded = _pkcs7_pad(data);
  var result = Vec[UInt8].new();
  var prev = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    prev.push(iv[i]);
    i = i + 1;
  }
  var bi = 0;
  while bi < padded.len() / 16 {
    var blk = Vec[UInt8].new();
    i = 0;
    while i < 16 {
      blk.push((padded[bi * 16 + i] as Int ^ prev[i] as Int) as UInt8);
      i = i + 1;
    }
    var ct = _aes_encrypt_block(&blk, 0, &sched.key, sched.rounds);
    prev = ct;
    i = 0;
    while i < 16 {
      result.push(ct[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  return Ok(result);
}

/// AES-CBC decrypt with padding removal.
/// Complexity: O(n).
pub fn aes_decrypt_cbc(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_decrypt_cbc: invalid key length"); }
  if iv.len() != 16 { return Err("aes_decrypt_cbc: IV must be 16 bytes"); }
  if data.len() % 16 != 0 { return Err("aes_decrypt_cbc: ciphertext length"); }
  let sched = _aes_key_expansion(key);
  var decrypted = Vec[UInt8].new();
  var prev = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    prev.push(iv[i]);
    i = i + 1;
  }
  var bi = 0;
  while bi < data.len() / 16 {
    var pt = _aes_decrypt_block(data, bi * 16, &sched.key, sched.rounds);
    i = 0;
    while i < 16 {
      decrypted.push((pt[i] as Int ^ prev[i] as Int) as UInt8);
      i = i + 1;
    }
    i = 0;
    while i < 16 {
      prev[i] = data[bi * 16 + i];
      i = i + 1;
    }
    bi = bi + 1;
  }
  return _pkcs7_unpad(&decrypted);
}

fn _inc_ctr(counter: &mut Vec[UInt8]) {
  var i = 15;
  while i >= 0 {
    var v = (counter[i] as Int) + 1;
    counter[i] = (v % 256) as UInt8;
    if v < 256 {
      return;
    }
    i = i - 1;
  }
}

fn _aes_crypt_ctr(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_ctr: invalid key length"); }
  if iv.len() != 16 { return Err("aes_ctr: IV/counter must be 16 bytes"); }
  let sched = _aes_key_expansion(key);
  var counter = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    counter.push(iv[i]);
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  var pos = 0;
  while pos < data.len() {
    var ks = _aes_encrypt_block(&counter, 0, &sched.key, sched.rounds);
    var blk = 0;
    while blk < 16 && pos + blk < data.len() {
      result.push((data[pos + blk] as Int ^ ks[blk] as Int) as UInt8);
      blk = blk + 1;
    }
    _inc_ctr(&mut counter);
    pos = pos + 16;
  }
  return Ok(result);
}

/// AES-CTR encrypt (stream cipher, no padding; decrypt is identical).
/// Complexity: O(n).
pub fn aes_encrypt_ctr(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var r = _aes_crypt_ctr(key, iv, data);
  match r {
    Ok(v) => v;
    Err(_) => Vec[UInt8].new();
  }
}

/// AES-CTR decrypt (same keystream as encrypt).
/// Complexity: O(n).
pub fn aes_decrypt_ctr(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var r = _aes_crypt_ctr(key, iv, data);
  match r {
    Ok(v) => v;
    Err(_) => Vec[UInt8].new();
  }
}

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
    if y_bit != 0 {
      var k = 0;
      while k < 16 {
        z[k] = (z[k] as Int ^ v[k] as Int) as UInt8;
        k = k + 1;
      }
    }
    let lsb = (v[15] as Int) & 1;
    var carry = 0;
    var k = 0;
    while k < 16 {
      let cur = v[k] as Int;
      let new_carry = cur & 1;
      v[k] = ((cur / 2) | (carry * 128)) as UInt8;
      carry = new_carry;
      k = k + 1;
    }
    if lsb != 0 {
      v[0] = (v[0] as Int ^ 0xE1) as UInt8;
    }
    bit = bit + 1;
  }
  return z;
}

fn _gcm_write_u64_be(buf: &mut Vec[UInt8], offset: Int, value: Int) {
  var v = value;
  var i = 7;
  while i >= 0 {
    buf[offset + i] = (v % 256) as UInt8;
    v = v / 256;
    i = i - 1;
  }
}

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
    i = 0;
    while i < rem {
      x[i] = (x[i] as Int ^ data[full_blocks * 16 + i] as Int) as UInt8;
      i = i + 1;
    }
    x = _gcm_gf_mult(&x, h);
  }
  return x;
}

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
  _gcm_write_u64_be(&mut len_block, 0, aad.len() * 8);
  _gcm_write_u64_be(&mut len_block, 8, ct.len() * 8);
  i = 0;
  while i < 16 {
    x[i] = (x[i] as Int ^ len_block[i] as Int) as UInt8;
    i = i + 1;
  }
  x = _gcm_gf_mult(&x, h);
  return x;
}

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

type _GcmOut = {
  ct: Vec[UInt8];
  tag: Vec[UInt8];
}

fn _gcm_crypt(key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> _GcmOut {
  let sched = _aes_key_expansion(key);
  var zero = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    zero.push(0);
    i = i + 1;
  }
  var h = _aes_encrypt_block(&zero, 0, &sched.key, sched.rounds);
  var j0 = _gcm_j0(nonce);
  var counter = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    counter.push(j0[i]);
    i = i + 1;
  }
  var ct = Vec[UInt8].new();
  var pos = 0;
  while pos < data.len() {
    _gcm_inc32(&mut counter);
    var ks = _aes_encrypt_block(&counter, 0, &sched.key, sched.rounds);
    var blk = 0;
    while blk < 16 && pos + blk < data.len() {
      ct.push((data[pos + blk] as Int ^ ks[blk] as Int) as UInt8);
      blk = blk + 1;
    }
    pos = pos + 16;
  }
  var s = _ghash(&h, aad, &ct);
  var ej0 = _aes_encrypt_block(&j0, 0, &sched.key, sched.rounds);
  var tag = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    tag.push((s[i] as Int ^ ej0[i] as Int) as UInt8);
    i = i + 1;
  }
  return _GcmOut{ ct: ct; tag: tag; };
}

/// AES-GCM encrypt (combined form: ciphertext with the 16-byte tag appended).
/// Implemented locally (the flat module's gcm name collides here).
/// Complexity: O(n).
pub fn aes_encrypt_gcm(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Vec[UInt8] {
  if !(_aes_valid_key(key)) { return Vec[UInt8].new(); }
  if iv.len() != 12 { return Vec[UInt8].new(); }
  let out = _gcm_crypt(key, iv, data, aad);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < out.ct.len() {
    result.push(out.ct[i]);
    i = i + 1;
  }
  i = 0;
  while i < out.tag.len() {
    result.push(out.tag[i]);
    i = i + 1;
  }
  return result;
}

/// AES-GCM decrypt and verify the tag. The ciphertext `data` carries the
/// 16-byte tag appended (see aes_encrypt_gcm).
/// Complexity: O(n).
pub fn aes_decrypt_gcm(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8], tag: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_decrypt_gcm: invalid key length"); }
  if iv.len() != 12 { return Err("aes_decrypt_gcm: nonce must be 12 bytes"); }
  if tag.len() != 16 {
    return Err("aes_decrypt_gcm: tag must be 16 bytes");
  }
  if data.len() < 16 {
    return Err("aes_decrypt_gcm: ciphertext too short");
  }
  var ct = Vec[UInt8].new();
  var i = 0;
  while i < data.len() - 16 {
    ct.push(data[i]);
    i = i + 1;
  }
  let out = _gcm_crypt(key, iv, &ct, aad);
  // constant-time tag comparison
  var diff: Int = 0;
  var j = 0;
  while j < 16 {
    diff = diff | ((out.tag[j] as Int) ^ (tag[j] as Int));
    j = j + 1;
  }
  if diff != 0 {
    return Err("aes_decrypt_gcm: authentication failed");
  }
  return Ok(out.ct);
}

fn _aes_crypt_cfb(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_cfb: invalid key length"); }
  if iv.len() != 16 { return Err("aes_cfb: IV must be 16 bytes"); }
  let sched = _aes_key_expansion(key);
  var feedback = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    feedback.push(iv[i]);
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  var pos = 0;
  while pos < data.len() {
    var ks = _aes_encrypt_block(&feedback, 0, &sched.key, sched.rounds);
    var blk = 0;
    while blk < 16 && pos + blk < data.len() {
      var out = (data[pos + blk] as Int ^ ks[blk] as Int) as UInt8;
      result.push(out);
      feedback[blk] = out;
      blk = blk + 1;
    }
    pos = pos + 16;
  }
  return Ok(result);
}

/// AES-CFB128 encrypt (stream, no padding).
/// Complexity: O(n).
pub fn aes_encrypt_cfb(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var r = _aes_crypt_cfb(key, iv, data);
  match r {
    Ok(v) => v;
    Err(_) => Vec[UInt8].new();
  }
}

fn _aes_crypt_ofb(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(_aes_valid_key(key)) { return Err("aes_ofb: invalid key length"); }
  if iv.len() != 16 { return Err("aes_ofb: IV must be 16 bytes"); }
  let sched = _aes_key_expansion(key);
  var feedback = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    feedback.push(iv[i]);
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  var pos = 0;
  while pos < data.len() {
    var ks = _aes_encrypt_block(&feedback, 0, &sched.key, sched.rounds);
    var blk = 0;
    while blk < 16 && pos + blk < data.len() {
      result.push((data[pos + blk] as Int ^ ks[blk] as Int) as UInt8);
      blk = blk + 1;
    }
    feedback = ks;
    pos = pos + 16;
  }
  return Ok(result);
}

/// AES-OFB encrypt (stream, no padding; decrypt is identical).
/// Complexity: O(n).
pub fn aes_encrypt_ofb(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var r = _aes_crypt_ofb(key, iv, data);
  match r {
    Ok(v) => v;
    Err(_) => Vec[UInt8].new();
  }
}

/// Generate a random 256-bit AES key from the system CSPRNG.
/// Complexity: O(1).
pub fn aes_generate_key() -> Vec[UInt8] {
  return crypto.secure_random_bytes(32);
}

/// Derive a 32-byte AES key from a passphrase using PBKDF2-HMAC-SHA256.
/// Complexity: O(iterations).
pub fn aes_key_from_passphrase(passphrase: &Vec[UInt8], salt: &Vec[UInt8], iterations: Int) -> Vec[UInt8] {
  if iterations < 1 { return Vec[UInt8].new(); }
  var it = iterations;
  if it > 1000000 { it = 1000000; }
  let h_len = 32;
  let block_count = 1;
  var result = Vec[UInt8].new();
  var bi = 1;
  while bi <= block_count {
    var u = Vec[UInt8].new();
    var j = 0;
    while j < salt.len() {
      u.push(salt[j]);
      j = j + 1;
    }
    u.push(0);
    u.push(0);
    u.push(0);
    u.push(1);
    var prev = crypto.hmac_sha256(passphrase, &u);
    var block_result = Vec[UInt8].new();
    j = 0;
    while j < prev.len() {
      block_result.push(prev[j]);
      j = j + 1;
    }
    var iter = 1;
    while iter < it {
      prev = crypto.hmac_sha256(passphrase, &prev);
      j = 0;
      while j < block_result.len() {
        block_result[j] = (block_result[j] as Int ^ prev[j] as Int) as UInt8;
        j = j + 1;
      }
      iter = iter + 1;
    }
    j = 0;
    while j < 32 && j < block_result.len() {
      result.push(block_result[j]);
      j = j + 1;
    }
    bi = bi + 1;
  }
  return result;
}

// ============================================================================
// ChaCha20 / ChaCha20-Poly1305
// ============================================================================

/// ChaCha20 stream encrypt with an explicit 32-bit block counter. Built on
/// xiom.chacha (the counter is seeded into the public ChaCha20 state).
/// Complexity: O(n).
pub fn chacha20_encrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], counter: Int, data: &Vec[UInt8]) -> Vec[UInt8] {
  var ctx = chacha.chacha20_new(key, nonce);
  ctx.state[12] = ctx.state[12] + counter;
  return chacha.chacha20_process(&ctx, data);
}

/// ChaCha20 stream decrypt (identical to encrypt).
/// Complexity: O(n).
pub fn chacha20_decrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], counter: Int, data: &Vec[UInt8]) -> Vec[UInt8] {
  return chacha20_encrypt(key, nonce, counter, data);
}

fn _poly_pad16(msg: &Vec[UInt8], out: &mut Vec[UInt8]) {
  var i = 0;
  while i < msg.len() {
    out.push(msg[i]);
    i = i + 1;
  }
  var pad = 16 - (msg.len() % 16);
  if pad == 16 { pad = 0; }
  i = 0;
  while i < pad {
    out.push(0);
    i = i + 1;
  }
}

fn _le64(out: &mut Vec[UInt8], v: Int) {
  var x = v;
  var i = 0;
  while i < 8 {
    out.push((x % 256) as UInt8);
    x = x / 256;
    i = i + 1;
  }
}

/// ChaCha20-Poly1305 AEAD encrypt (RFC 8439): returns ciphertext with the
/// 16-byte tag appended.
/// Complexity: O(n).
pub fn chacha20poly1305_encrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Vec[UInt8] {
  if key.len() != 32 { return Vec[UInt8].new(); }
  if nonce.len() != 12 { return Vec[UInt8].new(); }
  var base = chacha.chacha20_new(key, nonce);
  // Poly1305 one-time key = ChaCha20 block 0 keystream (first 32 bytes).
  base.state[12] = 0;
  var zeros = Vec[UInt8].new();
  var i = 0;
  while i < 64 {
    zeros.push(0);
    i = i + 1;
  }
  var ks0 = chacha.chacha20_process(&base, &zeros);
  var poly_key = Vec[UInt8].new();
  i = 0;
  while i < 32 {
    poly_key.push(ks0[i]);
    i = i + 1;
  }
  var ct = Vec[UInt8].new();
  var chunk_index = 1;
  var pos = 0;
  while pos < data.len() {
    base.state[12] = chunk_index;
    var blk = Vec[UInt8].new();
    var j = 0;
    while j < 64 {
      blk.push(0);
      j = j + 1;
    }
    var ks2 = chacha.chacha20_process(&base, &blk);
    var k = 0;
    while k < 64 && pos + k < data.len() {
      ct.push((data[pos + k] as Int ^ ks2[k] as Int) as UInt8);
      k = k + 1;
    }
    pos = pos + 64;
    chunk_index = chunk_index + 1;
  }
  var poly_msg = Vec[UInt8].new();
  _poly_pad16(aad, &mut poly_msg);
  _poly_pad16(&ct, &mut poly_msg);
  _le64(&mut poly_msg, aad.len());
  _le64(&mut poly_msg, ct.len());
  var tag = poly1305.poly1305_mac(&poly_key, &poly_msg);
  var result = Vec[UInt8].new();
  i = 0;
  while i < ct.len() {
    result.push(ct[i]);
    i = i + 1;
  }
  i = 0;
  while i < tag.len() {
    result.push(tag[i]);
    i = i + 1;
  }
  return result;
}

/// ChaCha20-Poly1305 AEAD decrypt and verify the tag.
/// Complexity: O(n).
pub fn chacha20poly1305_decrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8], tag: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if key.len() != 32 { return Err("chacha20poly1305_decrypt: key must be 32 bytes"); }
  if nonce.len() != 12 { return Err("chacha20poly1305_decrypt: nonce must be 12 bytes"); }
  if tag.len() != 16 { return Err("chacha20poly1305_decrypt: tag must be 16 bytes"); }
  var ct = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    ct.push(data[i]);
    i = i + 1;
  }
  var base = chacha.chacha20_new(key, nonce);
  base.state[12] = 0;
  var zeros = Vec[UInt8].new();
  i = 0;
  while i < 64 {
    zeros.push(0);
    i = i + 1;
  }
  var ks = chacha.chacha20_process(&base, &zeros);
  var poly_key = Vec[UInt8].new();
  i = 0;
  while i < 32 {
    poly_key.push(ks[i]);
    i = i + 1;
  }
  var poly_msg = Vec[UInt8].new();
  _poly_pad16(aad, &mut poly_msg);
  _poly_pad16(&ct, &mut poly_msg);
  _le64(&mut poly_msg, aad.len());
  _le64(&mut poly_msg, ct.len());
  var expected = poly1305.poly1305_mac(&poly_key, &poly_msg);
  var diff: Int = 0;
  i = 0;
  while i < 16 {
    diff = diff | ((expected[i] as Int) ^ (tag[i] as Int));
    i = i + 1;
  }
  if diff != 0 {
    return Err("chacha20poly1305_decrypt: authentication failed");
  }
  var pt = Vec[UInt8].new();
  var chunk_index = 1;
  var pos = 0;
  while pos < ct.len() {
    base.state[12] = chunk_index;
    var blk = Vec[UInt8].new();
    var j = 0;
    while j < 64 {
      blk.push(0);
      j = j + 1;
    }
    var ks2 = chacha.chacha20_process(&base, &blk);
    var k = 0;
    while k < 64 && pos + k < ct.len() {
      pt.push((ct[pos + k] as Int ^ ks2[k] as Int) as UInt8);
      k = k + 1;
    }
    pos = pos + 64;
    chunk_index = chunk_index + 1;
  }
  return Ok(pt);
}

// ============================================================================
// DES / 3DES
// ============================================================================

fn _be64_from_bytes(data: &Vec[UInt8], start: Int) -> Int {
  var v: Int = 0;
  var i = 0;
  while i < 8 {
    v = (v << 8) | (data[start + i] as Int);
    i = i + 1;
  }
  return v;
}

fn _bytes_from_be64(v: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 7;
  while i >= 0 {
    result.push(((v >> (i * 8)) & 0xFF) as UInt8);
    i = i - 1;
  }
  return result;
}

fn _des_key_int(key: &Vec[UInt8]) -> Result[Int, Str] {
  if key.len() != 8 {
    return Err("des: key must be 8 bytes");
  }
  return Ok(_be64_from_bytes(key, 0));
}

/// Legacy single-DES encrypt (ECB, 8-byte blocks, PKCS#7 padding).
/// Delegates to xiom.des. Interop only.
/// Complexity: O(n).
pub fn des_encrypt(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  var k = _des_key_int(key);
  if !k.is_ok { return Err(k.error); }
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    padded.push(data[i]);
    i = i + 1;
  }
  var pad_val = 8 - (data.len() % 8);
  if pad_val == 0 { pad_val = 8; }
  i = 0;
  while i < pad_val {
    padded.push(pad_val as UInt8);
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  var bi = 0;
  while bi < padded.len() / 8 {
    var block = _be64_from_bytes(&padded, bi * 8);
    var ct = des.des_encrypt_block(block, k.value);
    var bytes = _bytes_from_be64(ct);
    i = 0;
    while i < 8 {
      result.push(bytes[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  return Ok(result);
}

/// Legacy single-DES decrypt (ECB, padding removal). Interop only.
/// Complexity: O(n).
pub fn des_decrypt(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if data.len() % 8 != 0 {
    return Err("des: ciphertext length must be a multiple of 8");
  }
  var k = _des_key_int(key);
  if !k.is_ok { return Err(k.error); }
  var decrypted = Vec[UInt8].new();
  var bi = 0;
  while bi < data.len() / 8 {
    var block = _be64_from_bytes(data, bi * 8);
    var pt = des.des_decrypt_block(block, k.value);
    var bytes = _bytes_from_be64(pt);
    var i = 0;
    while i < 8 {
      decrypted.push(bytes[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  if decrypted.len() == 0 {
    return Err("des: empty ciphertext");
  }
  let pad_val = decrypted[decrypted.len() - 1] as Int;
  if pad_val < 1 || pad_val > 8 || pad_val > decrypted.len() {
    return Err("des: invalid padding");
  }
  var result = Vec[UInt8].new();
  var i = 0;
  while i < decrypted.len() - pad_val {
    result.push(decrypted[i]);
    i = i + 1;
  }
  return Ok(result);
}

/// 3DES-EDE encrypt (3 x 8-byte keys, PKCS#7 padding). Delegates to xiom.des.
/// Interop only.
/// Complexity: O(n).
pub fn triple_des_encrypt(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if key.len() != 24 {
    return Err("triple_des: key must be 24 bytes");
  }
  var k1 = _be64_from_bytes(key, 0);
  var k2 = _be64_from_bytes(key, 8);
  var k3 = _be64_from_bytes(key, 16);
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    padded.push(data[i]);
    i = i + 1;
  }
  var pad_val = 8 - (data.len() % 8);
  if pad_val == 0 { pad_val = 8; }
  i = 0;
  while i < pad_val {
    padded.push(pad_val as UInt8);
    i = i + 1;
  }
  var result = Vec[UInt8].new();
  var bi = 0;
  while bi < padded.len() / 8 {
    var block = _be64_from_bytes(&padded, bi * 8);
    var ct = des.des3_encrypt_block(block, k1, k2, k3);
    var bytes = _bytes_from_be64(ct);
    i = 0;
    while i < 8 {
      result.push(bytes[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  return Ok(result);
}

/// 3DES-EDE decrypt (padding removal). Interop only.
/// Complexity: O(n).
pub fn triple_des_decrypt(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if key.len() != 24 {
    return Err("triple_des: key must be 24 bytes");
  }
  if data.len() % 8 != 0 {
    return Err("triple_des: ciphertext length must be a multiple of 8");
  }
  var k1 = _be64_from_bytes(key, 0);
  var k2 = _be64_from_bytes(key, 8);
  var k3 = _be64_from_bytes(key, 16);
  var decrypted = Vec[UInt8].new();
  var bi = 0;
  while bi < data.len() / 8 {
    var block = _be64_from_bytes(data, bi * 8);
    var pt = des.des3_decrypt_block(block, k1, k2, k3);
    var bytes = _bytes_from_be64(pt);
    var i = 0;
    while i < 8 {
      decrypted.push(bytes[i]);
      i = i + 1;
    }
    bi = bi + 1;
  }
  if decrypted.len() == 0 {
    return Err("triple_des: empty ciphertext");
  }
  let pad_val = decrypted[decrypted.len() - 1] as Int;
  if pad_val < 1 || pad_val > 8 || pad_val > decrypted.len() {
    return Err("triple_des: invalid padding");
  }
  var result = Vec[UInt8].new();
  var i = 0;
  while i < decrypted.len() - pad_val {
    result.push(decrypted[i]);
    i = i + 1;
  }
  return Ok(result);
}

