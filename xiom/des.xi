// XIOM — DES-Lite: Simplified Feistel Block Cipher (Educational)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// DES-LITE is a simplified Feistel network block cipher for learning purposes.
// Unlike full DES (which uses 56-bit keys, 64-bit blocks, and 16 rounds with
// complex S-boxes and permutation tables), DES-Lite uses:
//   - 64-bit block size
//   - 64-bit key (all bits used, no parity stripping)
//   - 16 Feistel rounds
//   - Simple key schedule (rotation-based)
//   - Simplified S-box (8×4-bit substitution using a single 16-entry S-box)
//   - No IP/FP permutation (simplifies the structure)
//
// The Feistel structure is the same as DES:
//   Split block into L (32 bits) and R (32 bits).
//   For each round i:
//     L_new = R
//     R_new = L XOR F(R, K_i)
//   After 16 rounds, output = R || L (halves swapped).
//
// The F-function:
//   1. Expand R (32 bits → 48 bits) by duplicating certain bits.
//   2. XOR with the 48-bit round key.
//   3. Substitute: split into 8 groups of 6 bits, each → 4 bits via S-box.
//   4. Combine the 8×4 = 32 bits as output.
//
// WARNING: DES-Lite is NOT secure. It exists for educational purposes only.
//          For real encryption, use AES (xiom.crypto.aes_encrypt).

module xiom.des

// ============================================================================
// Simplified S-box: a 4×4 table (16 entries, each 4-bit output)
//
// This S-box maps a 6-bit input to a 4-bit output.
// Row = (bits 5, 0), Column = (bits 4-1).
// Values come from the first row of DES S-box 1 (well-known values).
// ============================================================================

const _DESLITE_SBOX: [64]Int = [
  14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7,
  0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8,
  4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0,
  15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13
];

/// Single S-box lookup: 6-bit input → 4-bit output.
/// Row = (input_bit_5, input_bit_0), Column = (input_bits 4-1).
fn _sbox_lookup(input6: Int) -> Int {
  let row = ((input6 >> 5) & 1) | ((input6 & 1) << 1);
  let col = (input6 >> 1) & 0x0F;
  return _DESLITE_SBOX[row * 16 + col];
}

// ============================================================================
// Expansion: 32 bits → 48 bits
//
// Expansion table (simplified E-like):
//   For each group of 4 input bits, output 6 bits by duplicating
//   the boundary bits (same pattern as DES E-table, but simpler mapping).
//
// Instead of a full E-table, we use bit-position-based expansion:
//   Group 0 (input bits 0-3): output bits 0-5 = {bit3, bit0, bit1, bit2, bit3, bit0}
//   Group 1 (input bits 4-7): output bits 6-11 = {bit7, bit4, bit5, bit6, bit7, bit4}
//   ...
//   Group 7 (input bits 28-31): output bits 42-47 = {bit31, bit28, ..., bit31, bit28}
//
// This is mathematically equivalent to a fixed permutation.
// ============================================================================

fn _expand_32_to_48(r: Int) -> Int {
  var result = 0;
  var group = 0;
  while group < 8 {
    let base = group * 4;
    // Extract the 4 bits of this group from r
    let b0 = (r >> base) & 1;
    let b1 = (r >> (base + 1)) & 1;
    let b2 = (r >> (base + 2)) & 1;
    let b3 = (r >> (base + 3)) & 1;

    // Output 6 bits: b3, b0, b1, b2, b3, b0
    let out_base = group * 6;
    result = result | (b3 << out_base);
    result = result | (b0 << (out_base + 1));
    result = result | (b1 << (out_base + 2));
    result = result | (b2 << (out_base + 3));
    result = result | (b3 << (out_base + 4));
    result = result | (b0 << (out_base + 5));

    group = group + 1;
  }

  return result & 0xFFFFFFFFFFFF;
}

// ============================================================================
// F-function: Feistel round function
//
// F(R, K_i):
//   1. Expand R (32 bits) to 48 bits.
//   2. XOR with round key K_i (48 bits).
//   3. Substitute: split 48 bits into 8 groups of 6 bits,
//      apply S-box (6→4), producing 32 bits.
//   4. Return the 32-bit result.
//
// Parameters:
//   r: 32-bit right half
//   round_key: 48-bit round key
// Returns: 32-bit F-function output
// ============================================================================

fn _f_function(r: Int, round_key: Int) -> Int {
  // Step 1: Expand 32 → 48
  var expanded = _expand_32_to_48(r);

  // Step 2: XOR with round key (48 bits)
  var xored = (expanded ^ round_key) & 0xFFFFFFFFFFFF;

  // Step 3: S-box substitution (48 → 32)
  // Split 48 bits into 8 groups of 6 bits
  var result = 0;
  var group = 0;
  while group < 8 {
    let input6 = (xored >> (group * 6)) & 0x3F;
    let output4 = _sbox_lookup(input6);
    result = result | (output4 << (group * 4));
    group = group + 1;
  }

  return result & 0xFFFFFFFF;
}

// ============================================================================
// Key Schedule: 64-bit key → 16 × 48-bit round keys
//
// Simplified key schedule:
//   1. Split 64-bit key into two 32-bit halves: K_L, K_R.
//   2. For each round i (0..15):
//      a. Rotate K_L left by (i % 7 + 1) bits.
//      b. Rotate K_R left by ((i * 3) % 11 + 1) bits.
//      c. Combine and extract 48 bits: round_key = (rotated_K_L || rotated_K_R) >> shift
//         and mask to 48 bits, using different shifts per round.
//   3. Return 16 round keys.
//
// This is NOT the DES key schedule. It's a simplified version that produces
// 16 distinct 48-bit round keys from a 64-bit key.
// ============================================================================

fn _key_schedule(key64: Int) -> Vec[Int] {
  var round_keys = Vec[Int].new();

  // Split key into two 32-bit halves
  var k_l = ((key64 >> 32) & 0xFFFFFFFF);
  var k_r = (key64 & 0xFFFFFFFF);

  var round = 0;
  while round < 16 {
    // Rotate K_L left by (round % 7 + 1)
    let rot_l = (round % 7) + 1;
    var rl = ((k_l << rot_l) | (k_l >> (32 - rot_l))) & 0xFFFFFFFF;

    // Rotate K_R left by ((round * 3) % 11 + 1)
    let rot_r = ((round * 3) % 11) + 1;
    var rr = ((k_r << rot_r) | (k_r >> (32 - rot_r))) & 0xFFFFFFFF;

    // Combine and extract 48 bits using round-dependent shift
    var combined = (rl << 32) | rr;
    let shift = (round * 5) % 17;
    var round_key = (combined >> shift) & 0xFFFFFFFFFFFF;

    round_keys.push(round_key);
    round = round + 1;
  }

  return round_keys;
}

// ============================================================================
// DES-Lite Block Encrypt / Decrypt
//
// Encryption:
//   1. Split 64-bit block into L (32 bits) and R (32 bits).
//   2. 16 Feistel rounds:
//        temp = R
//        R = L XOR F(R, K_i)
//        L = temp
//   3. Output = R || L (halves swapped after final round).
//
// Decryption: identical to encryption but with round keys reversed (K_15..K_0).
//
// Parameters:
//   block: 64-bit plaintext/ciphertext
//   key: 64-bit key
// Returns: 64-bit ciphertext/plaintext
// ============================================================================

/// Encrypt a single 64-bit block using DES-Lite.
pub fn des_encrypt_block(block: Int, key: Int) -> Int {
  var round_keys = _key_schedule(key);

  // Split block into left and right halves (32 bits each)
  var left = ((block >> 32) & 0xFFFFFFFF);
  var right = (block & 0xFFFFFFFF);

  // 16 Feistel rounds
  var round = 0;
  while round < 16 {
    var temp = right;
    right = (left ^ _f_function(right, round_keys[round])) & 0xFFFFFFFF;
    left = temp;
    round = round + 1;
  }

  // Combine with halves swapped (Feistel final step)
  var result = (right << 32) | left;
  return result;
}

/// Decrypt a single 64-bit block using DES-Lite.
/// Identical to encrypt but with round keys in reverse order.
pub fn des_decrypt_block(block: Int, key: Int) -> Int {
  var round_keys = _key_schedule(key);

  var left = ((block >> 32) & 0xFFFFFFFF);
  var right = (block & 0xFFFFFFFF);

  // 16 Feistel rounds with reversed key order
  var round = 15;
  while round >= 0 {
    var temp = right;
    right = (left ^ _f_function(right, round_keys[round])) & 0xFFFFFFFF;
    left = temp;
    round = round - 1;
  }

  var result = (right << 32) | left;
  return result;
}
