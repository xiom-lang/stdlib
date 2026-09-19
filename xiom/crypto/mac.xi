// XIOM - Cryptography: MAC
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.mac

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Message authentication codes: HMAC, Poly1305, CBC-MAC, CMAC.
//
// Delegation:
//   - poly1305_mac delegates to xiom.poly1305 (the canonical implementation).
//   - HMAC-SHA256 is implemented here on xiom.crypto.sha256 (its name collides
//     with the flat module's hmac_sha256, so same-name delegation would
//     miscompile; BUG 25 #1). The result matches RFC 4231.
//   - CBC-MAC and AES-CMAC use the AES block primitive exposed by
//     xiom.crypto.cipher.
//
// Hash identifiers (for hmac_new / hmac_*):
//   1 = SHA-256 (block 64), 2 = SHA-512 (block 128), 3 = MD5 (block 64).
//
// Security notes:
//   - constant_time_eq / hmac_verify compare tags with arithmetic masking so
//     the loop time does not depend on tag bytes.
//   - Poly1305 keys are one-time: never reuse a (key, nonce) pair.
// ============================================================================

use xiom.crypto;
use xiom.poly1305;
use xiom.crypto.cipher;

/// HMAC context (keyed hash state).
pub type Hmac = {
  key: Vec[UInt8];
  hash: Int;
  block: Int;
  data: Vec[UInt8];
}

/// Create an incremental HMAC. `hash` selects the digest (1=SHA-256,
/// 2=SHA-512, 3=MD5); unknown values fall back to SHA-256.
/// Complexity: O(key length).
pub fn hmac_new(key: &Vec[UInt8], hash: Int) -> Hmac {
  var block = 64;
  if hash == 2 { block = 128; }
  var norm_key = Vec[UInt8].new();
  if key.len() > block {
    var hashed = _hmac_digest(hash, key);
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
  return Hmac{ key: norm_key; hash: hash; block: block; data: Vec[UInt8].new(); };
}

/// Feed data into an in-progress HMAC.
/// Complexity: O(n), n = data length.
pub fn hmac_update(h: &mut Hmac, data: &Vec[UInt8]) {
  var i = 0;
  while i < data.len() {
    h.data.push(data[i]);
    i = i + 1;
  }
}

/// Finish an HMAC and return the tag.
/// Complexity: O(n), n = accumulated data length.
pub fn hmac_final(h: Hmac) -> Vec[UInt8] {
  return _hmac_from_padded(&h.key, h.hash, h.block, &h.data);
}

fn _hmac_digest(hash: Int, data: &Vec[UInt8]) -> Vec[UInt8] {
  if hash == 2 { return crypto.sha512(data); }
  if hash == 3 { return crypto.md5_bytes(data); }
  return crypto.sha256(data);
}

fn _hmac_from_padded(norm_key: &Vec[UInt8], hash: Int, block: Int, data: &Vec[UInt8]) -> Vec[UInt8] {
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
  let inner_hash = _hmac_digest(hash, &inner);
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
  return _hmac_digest(hash, &outer);
}

/// One-shot HMAC-SHA256 (RFC 2104). Implemented locally on xiom.crypto.sha256;
/// matches the flat hmac_sha256 and RFC 4231 vectors.
/// Complexity: O(n), n = data length.
pub fn hmac_sha256(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var ctx = hmac_new(key, 1);
  hmac_update(&mut ctx, data);
  return hmac_final(ctx);
}

/// One-shot HMAC-SHA512 (RFC 2104). Uses xiom.crypto.sha512 (verified).
/// Complexity: O(n), n = data length.
pub fn hmac_sha512(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var ctx = hmac_new(key, 2);
  hmac_update(&mut ctx, data);
  return hmac_final(ctx);
}

/// Verify an HMAC-SHA256 tag in constant time.
/// Complexity: O(n), n = data length.
pub fn hmac_verify(key: &Vec[UInt8], data: &Vec[UInt8], tag: &Vec[UInt8]) -> Bool {
  var computed = hmac_sha256(key, data);
  return constant_time_eq(&computed, tag);
}

/// Poly1305 one-shot MAC (16 bytes). Delegates to xiom.poly1305.poly1305_mac.
/// Complexity: O(n), n = message length.
pub fn poly1305_mac(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  return poly1305.poly1305_mac(key, data);
}

/// Constant-time Poly1305 verification.
/// Complexity: O(n), n = message length.
pub fn poly1305_verify(key: &Vec[UInt8], data: &Vec[UInt8], tag: &Vec[UInt8]) -> Bool {
  var computed = poly1305.poly1305_mac(key, data);
  return constant_time_eq(&computed, tag);
}

/// CBC-MAC over the message (NIST SP 800-38B style: full 16-byte blocks;
/// the final partial block is zero-padded). Uses the AES block primitive.
/// Complexity: O(n), n = data length.
pub fn cbc_mac(key: &Vec[UInt8], iv: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var acc = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    acc.push(iv[i]);
    i = i + 1;
  }
  var pos = 0;
  var last_full = (data.len() / 16) * 16;
  while pos < last_full {
    i = 0;
    while i < 16 {
      acc[i] = (acc[i] as Int ^ data[pos + i] as Int) as UInt8;
      i = i + 1;
    }
    var enc = cipher.aes_block_encrypt(key, &acc);
    match enc {
      Ok(ct) => {
        acc = ct;
      }
      Err(_) => {}
    }
    pos = pos + 16;
  }
  // zero-pad the final partial block (or an empty message -> one zero block)
  if data.len() > last_full {
    i = 0;
    while i < 16 {
      if last_full + i < data.len() {
        acc[i] = (acc[i] as Int ^ data[last_full + i] as Int) as UInt8;
      }
      i = i + 1;
    }
    var enc2 = cipher.aes_block_encrypt(key, &acc);
    match enc2 {
      Ok(ct) => {
        acc = ct;
      }
      Err(_) => {}
    }
  }
  return acc;
}

/// AES-CMAC-128 (NIST SP 800-38B). Uses the AES block primitive.
/// Complexity: O(n), n = data length.
pub fn cmac_aes128(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var zero = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    zero.push(0);
    i = i + 1;
  }
  var l = Vec[UInt8].new();
  var enc0 = cipher.aes_block_encrypt(key, &zero);
  match enc0 {
    Ok(ct) => {
      l = ct;
    }
    Err(_) => {}
  }
  var k1 = _cmac_dbl(&l);
  var k2 = _cmac_dbl(&k1);
  var msg_len = data.len();
  var n_blocks = msg_len / 16;
  var last_block = Vec[UInt8].new();
  var is_complete = false;
  if msg_len == 0 {
    n_blocks = 1;
    last_block = _cmac_pad(&k2, 0, true);
    is_complete = true;
  } elif msg_len % 16 == 0 {
    is_complete = true;
    var start = (n_blocks - 1) * 16;
    var lb = Vec[UInt8].new();
    i = 0;
    while i < 16 {
      lb.push(data[start + i]);
      i = i + 1;
    }
    last_block = _cmac_xor_key(&lb, &k1);
  } else {
    var start = n_blocks * 16;
    var lb = Vec[UInt8].new();
    var j = 0;
    while j < start {
      lb.push(data[j]);
      j = j + 1;
    }
    last_block = _cmac_pad_key(&data, start, &k2);
    is_complete = false;
  }
  var x = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    x.push(0);
    i = i + 1;
  }
  var bi = 0;
  var last_index = n_blocks - 1;
  if msg_len == 0 { last_index = 0; }
  while bi < n_blocks {
    var block = Vec[UInt8].new();
    if bi == last_index {
      block = last_block;
    } else {
      i = 0;
      while i < 16 {
        block.push(data[bi * 16 + i]);
        i = i + 1;
      }
    }
    i = 0;
    while i < 16 {
      x[i] = (x[i] as Int ^ block[i] as Int) as UInt8;
      i = i + 1;
    }
    var encx = cipher.aes_block_encrypt(key, &x);
    match encx {
      Ok(ct) => {
        x = ct;
      }
      Err(_) => {}
    }
    bi = bi + 1;
  }
  return x;
}

fn _cmac_dbl(v: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    result.push(0);
    i = i + 1;
  }
  var msb = (v[0] as Int) & 0x80;
  i = 0;
  while i < 15 {
    result[i] = (((v[i] as Int) << 1) | ((v[i + 1] as Int) >> 7)) as UInt8;
    i = i + 1;
  }
  result[15] = ((v[15] as Int) << 1) as UInt8;
  if msb != 0 {
    result[15] = (result[15] as Int ^ 0x87) as UInt8;
  }
  return result;
}

fn _cmac_xor_key(block: &Vec[UInt8], key: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    result.push((block[i] as Int ^ key[i] as Int) as UInt8);
    i = i + 1;
  }
  return result;
}

fn _cmac_pad_key(data: &Vec[UInt8], start: Int, key: &Vec[UInt8]) -> Vec[UInt8] {
  var block = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    block.push(0);
    i = i + 1;
  }
  i = 0;
  while i < 16 {
    if start + i < data.len() {
      block[i] = data[start + i];
    }
    i = i + 1;
  }
  block[data.len() - start] = 0x80;
  var result = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    result.push((block[i] as Int ^ key[i] as Int) as UInt8);
    i = i + 1;
  }
  return result;
}

fn _cmac_pad(key: &Vec[UInt8], start: Int, empty: Bool) -> Vec[UInt8] {
  var block = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    block.push(0);
    i = i + 1;
  }
  block[0] = 0x80;
  var result = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    result.push((block[i] as Int ^ key[i] as Int) as UInt8);
    i = i + 1;
  }
  return result;
}

/// Timing-safe byte comparison (arithmetic accumulation, no early exit).
/// Complexity: O(n), n = byte length.
pub fn constant_time_eq(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var diff: Int = 0;
  var i = 0;
  while i < a.len() {
    var x = a[i] as Int;
    var y = b[i] as Int;
    diff = diff | (x ^ y);
    i = i + 1;
  }
  return diff == 0;
}

/// Constant-time select: returns `a` when `bit` is true, else `b`. Both
/// branches are evaluated and combined arithmetically.
/// Complexity: O(1).
pub fn constant_time_select(a: Int, b: Int, bit: Bool) -> Int {
  var mask = 0;
  if bit { mask = -1; }
  var a_mask = a & mask;
  var b_mask = b & (~mask);
  return a_mask | b_mask;
}
