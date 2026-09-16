// XIOM -- Poly1305 One-Time Authenticator (RFC 8439)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Poly1305 is a one-time message authentication code (MAC) designed by
// Daniel J. Bernstein. It takes a 32-byte one-time key and a message of
// arbitrary length, and produces a 16-byte (128-bit) authenticator tag.
//
// Algorithm (RFC 8439 Section 2.5):
//   1. The key is split into two 16-byte halves: r (clamped) and s.
//   2. The message is processed in 16-byte blocks; each block is appended
//      with a 0x01 byte to form a 129-bit number (little-endian).
//   3. Accumulator h starts at 0. For each block n:
//        h = (h + n) * r  mod (2^130 - 5)
//   4. Finally: tag = (h + s) mod 2^128, output as 16 little-endian bytes.
//
// Implementation Strategy:
//   Since XIOM Int is 64-bit signed (i64, max ~= 9.22e18), we cannot directly
//   represent 130-bit numbers. We use 5 limbs of 26 bits each (base B = 2^26).
//   - Each limb fits in i64 (< 2^26 ~= 67 million)
//   - Product of two limbs: < 2^52 ~= 4.5e15, fits in i64
//   - Sum of up to 5 partial products: < 2^54 ~= 1.8e16, fits in i64
//
//   Base B = 2^26 = 67108864. 5 limbs give B^5 = 2^130.
//   The prime is p = 2^130 - 5 = B^5 - 5.
//
//   Reduction uses: B^5 == 5 (mod p), so for j >= 0: B^(5+j) == 5 * B^j.
//
// Security notes:
//   - The key MUST be used only once (hence "one-time authenticator").
//     Reusing a key allows forgery.
//   - r is clamped: certain bits are cleared to ensure efficient implementation
//     and prevent some classes of attacks.
//   - Combined with ChaCha20, this forms ChaCha20-Poly1305 (AEAD).

module xiom.poly1305

// ============================================================================
// 32-bit Unsigned Helpers
// ============================================================================

fn _u32_mask(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

/// Pack 4 little-endian bytes into a u32 word.
fn _pack_u32_le(bytes: &Vec[UInt8], offset: Int) -> Int {
  var result = 0;
  result = result | ((bytes[offset] as Int) & 0xFF);
  result = result | (((bytes[offset + 1] as Int) & 0xFF) << 8);
  result = result | (((bytes[offset + 2] as Int) & 0xFF) << 16);
  result = result | (((bytes[offset + 3] as Int) & 0xFF) << 24);
  return result & 0xFFFFFFFF;
}

// ============================================================================
// Base B = 2^26 limb arithmetic
//
// We represent 130-bit integers as 5 signed 64-bit values (h0..h4),
// each carrying 26 bits. The value is:
//   V = h0 + h1*B + h2*B^2 + h3*B^3 + h4*B^4
//
// After operations, limbs may temporarily exceed 26 bits, but we carry
// propagate to keep them bounded.
// ============================================================================

const _POLY_B: Int = 67108864;   // 2^26
const _POLY_BMASK: Int = 67108863; // 2^26 - 1
const _POLY_P0: Int = 67108859;  // 2^26 - 5 (lowest limb of prime)
const _POLY_PLIMB: Int = 67108863; // 2^26 - 1 (upper limbs of prime)

// ============================================================================
// r-Clamping (RFC 8439 Section 2.5.1)
//
// Before use, the 16-byte r value is clamped:
//   r[3]  &= 0x0F  (clear top 4 bits of the 4th byte)
//   r[7]  &= 0x0F
//   r[11] &= 0x0F
//   r[15] &= 0x0F
//   r[4]  &= 0xFC  (clear bottom 2 bits of the 5th byte)
//   r[8]  &= 0xFC
//   r[12] &= 0xFC
//
// This ensures r is a multiple of 4 and < 2^124, which speeds up
// modular reduction and prevents certain attacks.
// ============================================================================

fn _clamp_r(r_bytes: &mut Vec[UInt8]) {
  r_bytes[3] = (r_bytes[3] as Int & 0x0F) as UInt8;
  r_bytes[7] = (r_bytes[7] as Int & 0x0F) as UInt8;
  r_bytes[11] = (r_bytes[11] as Int & 0x0F) as UInt8;
  r_bytes[15] = (r_bytes[15] as Int & 0x0F) as UInt8;
  r_bytes[4] = (r_bytes[4] as Int & 0xFC) as UInt8;
  r_bytes[8] = (r_bytes[8] as Int & 0xFC) as UInt8;
  r_bytes[12] = (r_bytes[12] as Int & 0xFC) as UInt8;
}

/// Convert 16 little-endian bytes into 5 base-2^26 limbs.
/// Used for converting r (after clamping) and s values.
/// Assumes input bytes represent a number < 2^128.
fn _bytes_to_limbs(bytes: &Vec[UInt8], offset: Int) -> Vec[Int] {
  var limbs = Vec[Int].new();

  // Read as 4 little-endian u32 words, then split into 26-bit limbs.
  // word0 (bytes 0-3): bits 0-31
  // word1 (bytes 4-7): bits 32-63
  // word2 (bytes 8-11): bits 64-95
  // word3 (bytes 12-15): bits 96-127

  var w0 = _pack_u32_le(bytes, offset);
  var w1 = _pack_u32_le(bytes, offset + 4);
  var w2 = _pack_u32_le(bytes, offset + 8);
  var w3 = _pack_u32_le(bytes, offset + 12);

  // Limb 0: bits 0-25  (from w0)
  limbs.push(w0 & _POLY_BMASK);

  // Limb 1: bits 26-51 (w0 >> 26) | ((w1 & 0x3FFFF) << 6)
  // w0 contributes bits 26-31 (6 bits), w1 contributes bits 0-19 (20 bits) = 26 total
  var l1 = ((w0 >> 26) & 0x3F) | ((w1 & 0xFFFFF) << 6);
  limbs.push(l1 & _POLY_BMASK);

  // Limb 2: bits 52-77 (w1 >> 20) | ((w2 & 0xFFF) << 12)
  // w1 contributes bits 20-31 (12 bits), w2 contributes bits 0-13 (14 bits) = 26 total
  var l2 = ((w1 >> 20) & 0xFFF) | ((w2 & 0x3FFF) << 12);
  limbs.push(l2 & _POLY_BMASK);

  // Limb 3: bits 78-103 (w2 >> 14) | ((w3 & 0x3FFFF) << 18)
  // w2 contributes bits 14-31 (18 bits), w3 contributes bits 0-7 (8 bits) = 26 total
  var l3 = ((w2 >> 14) & 0x3FFFF) | ((w3 & 0xFF) << 18);
  limbs.push(l3 & _POLY_BMASK);

  // Limb 4: bits 104-127 (w3 >> 8) & 0xFFFFFF
  // w3 contributes bits 8-31 = exactly the 24 bits of positions 104-127.
  var l4 = (w3 >> 8) & 0xFFFFFF;
  limbs.push(l4 & _POLY_BMASK);

  return limbs;
}

/// Convert a 16-byte message block (plus 0x01 padding byte) to 5 base-2^26 limbs.
/// The 0x01 byte is appended at position 16 (bit 128), making the block
/// a 129-bit number: n = le_bytes_to_num(block) + 2^128.
fn _block_to_limbs(block: &Vec[UInt8], start: Int) -> Vec[Int] {
  var limbs = _bytes_to_limbs(block, start);
  // Add 2^128 = B^5 / B = B^4 = 2^104. In our representation, this goes to limb 4.
  // But wait: 2^128 in our base is: 2^128 = 2^(26*4 + 24) = 2^24 * B^4.
  // Actually, let's recalculate: 128 bits in base 2^26:
  // 128 / 26 = 4 remainder 24. So 2^128 = 2^24 * B^4 = 16777216 * (2^26)^4.
  // In our limb representation, limb 4 gets +2^24 = 16777216.
  limbs[4] = limbs[4] + 16777216;
  return limbs;
}

/// Carry propagation: ensure each limb is < B (2^26) by propagating carries upward.
/// Reduces a 5-limb value (possibly with overflows) to canonical form.
fn _carry_propagate(limbs: &mut Vec[Int]) {
  // Carry from limb 0 to limb 1
  var carry = limbs[0] >> 26;
  limbs[0] = limbs[0] & _POLY_BMASK;
  limbs[1] = limbs[1] + carry;

  // Carry from limb 1 to limb 2
  carry = limbs[1] >> 26;
  limbs[1] = limbs[1] & _POLY_BMASK;
  limbs[2] = limbs[2] + carry;

  // Carry from limb 2 to limb 3
  carry = limbs[2] >> 26;
  limbs[2] = limbs[2] & _POLY_BMASK;
  limbs[3] = limbs[3] + carry;

  // Carry from limb 3 to limb 4
  carry = limbs[3] >> 26;
  limbs[3] = limbs[3] & _POLY_BMASK;
  limbs[4] = limbs[4] + carry;
}

/// Multiply two 5-limb values h and r, returning h*r mod (2^130 - 5).
///
/// Computes the full 10-limb product using schoolbook multiplication,
/// then reduces using the identity B^5 == 5 (mod p).
///
/// Each limb of h and r is < 2^26, so each partial product h[i]*r[j] < 2^52.
/// Summing up to 5 such products (for each output limb) gives < 5 * 2^52 < 2^55,
/// well within i64 range.
fn _poly_mul_mod(h: &Vec[Int], r: &Vec[Int]) -> Vec[Int] {
  // Compute full product: 10 limbs (0..9), each less than 5 * 2^52 < 2^55
  var d0 = h[0] * r[0];
  var d1 = h[0] * r[1] + h[1] * r[0];
  var d2 = h[0] * r[2] + h[1] * r[1] + h[2] * r[0];
  var d3 = h[0] * r[3] + h[1] * r[2] + h[2] * r[1] + h[3] * r[0];
  var d4 = h[0] * r[4] + h[1] * r[3] + h[2] * r[2] + h[3] * r[1] + h[4] * r[0];
  var d5 = h[1] * r[4] + h[2] * r[3] + h[3] * r[2] + h[4] * r[1];
  var d6 = h[2] * r[4] + h[3] * r[3] + h[4] * r[2];
  var d7 = h[3] * r[4] + h[4] * r[3];
  var d8 = h[4] * r[4];

  // Reduction: B^5 == 5 (mod p), so B^(5+j) == 5 * B^j (mod p)
  // d5*B^5 == 5*d5, d6*B^6 == 5*d6*B, d7*B^7 == 5*d7*B^2, etc.
  // So:
  //   c0 = d0 + 5*d5
  //   c1 = d1 + 5*d6
  //   c2 = d2 + 5*d7
  //   c3 = d3 + 5*d8
  //   c4 = d4

  var result = Vec[Int].new();
  result.push(d0 + 5 * d5);
  result.push(d1 + 5 * d6);
  result.push(d2 + 5 * d7);
  result.push(d3 + 5 * d8);
  result.push(d4);

  // Carry propagate. After this, limbs 0-3 < 2^26, limb 4 may overflow.
  _carry_propagate(&mut result);

  // If limb 4 still has overflow (>= 2^26), the extra * B^4 * B = extra * B^5
  // == extra * 5. Add this back to limb 0 and carry again.
  var extra = result[4] >> 26;
  while extra > 0 {
    result[4] = result[4] & _POLY_BMASK;
    result[0] = result[0] + 5 * extra;
    _carry_propagate(&mut result);
    extra = result[4] >> 26;
  }

  return result;
}

/// Finalize: compute (h + s) mod 2^128, return as 16 little-endian bytes.
fn _finalize(h: &Vec[Int], s: &Vec[Int]) -> Vec[UInt8] {
  // Add s to h (limb-wise, then carry propagate)
  var sum = Vec[Int].new();
  sum.push(h[0] + s[0]);
  sum.push(h[1] + s[1]);
  sum.push(h[2] + s[2]);
  sum.push(h[3] + s[3]);
  sum.push(h[4] + s[4]);

  _carry_propagate(&mut sum);

  // Tag is the low 128 bits of (h + s): limbs 0-4, with limb 4 only
  // contributing 24 bits (4*26 + 24 = 128). Serialize bits 0-127 as 16
  // little-endian bytes.

  var tag = Vec[UInt8].new();

  // Serialize the low 128 bits of `sum` as 16 little-endian bytes.
  //
  // BUG FIX (2026-08-25, kat_crypto_chacha20poly1305_rfc8439): the previous
  // serialization placed each limb at BYTE offset k*26/8 and silently
  // ignored the intra-byte bit offset (limbs sit at bit offsets 0/2/4/6/0),
  // producing garbage tags for any non-trivial value. The correct method is
  // repeated division of the limb vector by 256: byte[i] = value mod 256,
  // value = value / 256, done in base-2^26 limb space. All intermediates
  // stay far below i64 range: rem*B + limb <= 255*2^26 + 2^26 < 2^34.
  var t = Vec[Int].new();
  var q = 0;
  while q < 5 {
    t.push(sum[q]);
    q = q + 1;
  }
  // Mask limb 4 to its 24 significant bits (bits 104-127).
  t[4] = t[4] & 0xFFFFFF;

  var tag = Vec[UInt8].new();
  var bi = 0;
  while bi < 16 {
    var rem = 0;
    var k = 4;
    while k >= 0 {
      var cur = rem * _POLY_B + t[k];
      t[k] = cur / 256;
      rem = cur - (cur / 256) * 256;
      k = k - 1;
    }
    tag.push(rem as UInt8);
    bi = bi + 1;
  }

  return tag;
}

// ============================================================================
// Poly1305 MAC -- Main Function
//
// Computes a 16-byte authenticator tag for the given message under the
// given 32-byte one-time key.
//
// Algorithm:
//   1. Split key: r = key[0..15] (clamped), s = key[16..31]
//   2. Initialize accumulator h = 0 (all 5 limbs = 0)
//   3. Process each 16-byte message block:
//      a. Convert block + 0x01 to 5 limbs (n)
//      b. h = h + n (limb-wise)
//      c. h = h * r mod p
//   4. Finalize: tag = low 128 bits of (h + s)
//
// Parameters:
//   key: 32-byte one-time key (Vec[Int] where each element is a byte value 0-255,
//        or Vec[UInt8])
//   msg: message to authenticate
// Returns: 16-byte tag as Vec[Int] (each element 0-255)
//
// IMPORTANT: The key MUST be used only once per key. Key reuse breaks security.
// Use with ChaCha20 as ChaCha20-Poly1305 AEAD for authenticated encryption.
// ============================================================================

pub fn poly1305_mac(key: &Vec[UInt8], msg: &Vec[UInt8]) -> Vec[UInt8] {
  // Step 1: Split and clamp key
  var r_bytes = Vec[UInt8].new();
  var s_bytes = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    r_bytes.push(key[i]);
    i = i + 1;
  }
  while i < 32 {
    s_bytes.push(key[i]);
    i = i + 1;
  }

  _clamp_r(&mut r_bytes);

  // Convert r and s to limb representation
  var r_limbs = _bytes_to_limbs(&r_bytes, 0);
  var s_limbs = _bytes_to_limbs(&s_bytes, 0);

  // Step 2: Initialize accumulator h = 0
  var h = Vec[Int].new();
  i = 0;
  while i < 5 {
    h.push(0);
    i = i + 1;
  }

  // Step 3: Process message blocks
  let msg_len = msg.len();
  var pos = 0;

  while pos < msg_len {
    // Determine block size (16 bytes, possibly shorter for last block)
    var block_size = 16;
    if pos + 16 > msg_len {
      block_size = msg_len - pos;
    }

    // Build block with padding
    var block = Vec[UInt8].new();
    var j = 0;
    while j < block_size {
      block.push(msg[pos + j]);
      j = j + 1;
    }
    while j < 16 {
      block.push(0);
      j = j + 1;
    }

    // Add the 0x01 byte: we set bit 128 via the +2^128 in _block_to_limbs
    var n_limbs = _block_to_limbs(&block, 0);

    // h = h + n (limb-wise)
    h[0] = h[0] + n_limbs[0];
    h[1] = h[1] + n_limbs[1];
    h[2] = h[2] + n_limbs[2];
    h[3] = h[3] + n_limbs[3];
    h[4] = h[4] + n_limbs[4];

    _carry_propagate(&mut h);

    // h = h * r mod p
    h = _poly_mul_mod(&h, &r_limbs);

    pos = pos + 16;
  }

  // Step 4: Finalize -- tag = low 128 bits of (h + s)
  var tag = _finalize(&h, &s_limbs);
  return tag;
}
