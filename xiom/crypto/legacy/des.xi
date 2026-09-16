// XIOM -- DES / 3DES (FIPS 46-3)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
// ============================================================================
// !!! LEGACY / DEPRECATED -- DO NOT USE IN NEW SYSTEMS !!!
//
// DES provides ~56-bit effective key strength and is breakable with modest
// resources (NIST withdrew FIPS 46-3 in 2005). 3DES remains listed only for
// interop with ancient systems and is deprecated by SP 800-131A rev 2.
// Kept solely for compatibility with legacy data and protocols. Never use
// for new encryption. See docs/STDLIB_READINESS_PLAN.md phase O.
// ============================================================================
// PHYSICAL LOCATION (2026-09-12): this file was moved to
// stdlib/xiom/crypto/legacy/. The module name is unchanged (API freeze),
// so existing `use xiom.des;` imports keep working; new code must not
// import it.
//
// Full FIPS Publication 46-3 Data Encryption Standard.
//
// Implements the complete 16-round Feistel block cipher with:
//   - Initial Permutation (IP) and Final Permutation (FP = IP^-1)
//   - Expansion function E (32->48 bits)
//   - Eight standard DES S-boxes (S1 through S8)
//   - P-box permutation (32 bits)
//   - Complete key schedule: PC-1, 28-bit half rotations (C/D),
//     PC-2 round-key selection
//   - Triple-DES in EDE mode (Encrypt-Decrypt-Encrypt)
//
// All bit numbering follows the DES convention: bit 1 is the
// most-significant bit of the block / key (MSB-first).
//
// NOTE ON TABLE STORAGE: FIPS defines the permutation/substitution tables as
// constants. The XIOM compiler currently mis-compiles module-level const array
// literals (only the length and first element are materialized). Tables are
// therefore built at runtime into Vec[Int] by the _build_*() helpers below.
// This is functionally identical to constant tables but works around the
// codegen defect. The tables are rebuilt per block operation; callers needing
// throughput should reuse 3DES/multiple blocks in one call.
//
// SECURITY NOTES:
//   - DES provides only 56-bit key space; 3DES (EDE) is the legacy
//     recommendation for compatibility. Prefer AES for new work.
//   - Single DES is considered deprecated (SWEET32 attack, < 2^56 security).

module xiom.des

// ============================================================================
// Table Builders -- real FIPS 46-3 tables, built at runtime
// ============================================================================

/// Initial Permutation (IP) -- FIPS 46-3 Table 3-2.
/// IP[i] is the source bit position (1..64, MSB-first) for output bit (i+1).
fn _build_ip() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(58); t.push(50); t.push(42); t.push(34); t.push(26); t.push(18); t.push(10); t.push(2);
  t.push(60); t.push(52); t.push(44); t.push(36); t.push(28); t.push(20); t.push(12); t.push(4);
  t.push(62); t.push(54); t.push(46); t.push(38); t.push(30); t.push(22); t.push(14); t.push(6);
  t.push(64); t.push(56); t.push(48); t.push(40); t.push(32); t.push(24); t.push(16); t.push(8);
  t.push(57); t.push(49); t.push(41); t.push(33); t.push(25); t.push(17); t.push(9); t.push(1);
  t.push(59); t.push(51); t.push(43); t.push(35); t.push(27); t.push(19); t.push(11); t.push(3);
  t.push(61); t.push(53); t.push(45); t.push(37); t.push(29); t.push(21); t.push(13); t.push(5);
  t.push(63); t.push(55); t.push(47); t.push(39); t.push(31); t.push(23); t.push(15); t.push(7);
  return t;
}

/// Final Permutation (FP) -- FIPS 46-3 Table 3-2, inverse of IP.
/// FP[i] is the source bit position (1..64) for output bit (i+1).
fn _build_fp() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(40); t.push(8); t.push(48); t.push(16); t.push(56); t.push(24); t.push(64); t.push(32);
  t.push(39); t.push(7); t.push(47); t.push(15); t.push(55); t.push(23); t.push(63); t.push(31);
  t.push(38); t.push(6); t.push(46); t.push(14); t.push(54); t.push(22); t.push(62); t.push(30);
  t.push(37); t.push(5); t.push(45); t.push(13); t.push(53); t.push(21); t.push(61); t.push(29);
  t.push(36); t.push(4); t.push(44); t.push(12); t.push(52); t.push(20); t.push(60); t.push(28);
  t.push(35); t.push(3); t.push(43); t.push(11); t.push(51); t.push(19); t.push(59); t.push(27);
  t.push(34); t.push(2); t.push(42); t.push(10); t.push(50); t.push(18); t.push(58); t.push(26);
  t.push(33); t.push(1); t.push(41); t.push(9); t.push(49); t.push(17); t.push(57); t.push(25);
  return t;
}

/// Expansion function E -- FIPS 46-3 Table 3-3.
/// Expands a 32-bit half-block to 48 bits by duplicating boundary bits.
/// E[i] is the source bit position (1..32) for output bit (i+1).
fn _build_e() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(32); t.push(1); t.push(2); t.push(3); t.push(4); t.push(5);
  t.push(4); t.push(5); t.push(6); t.push(7); t.push(8); t.push(9);
  t.push(8); t.push(9); t.push(10); t.push(11); t.push(12); t.push(13);
  t.push(12); t.push(13); t.push(14); t.push(15); t.push(16); t.push(17);
  t.push(16); t.push(17); t.push(18); t.push(19); t.push(20); t.push(21);
  t.push(20); t.push(21); t.push(22); t.push(23); t.push(24); t.push(25);
  t.push(24); t.push(25); t.push(26); t.push(27); t.push(28); t.push(29);
  t.push(28); t.push(29); t.push(30); t.push(31); t.push(32); t.push(1);
  return t;
}

/// Permutation P -- FIPS 46-3 Table 3-5.
/// Permutes the 32-bit S-box output before XOR with the left half.
/// P[i] is the source bit position (1..32) for output bit (i+1).
fn _build_p() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(16); t.push(7); t.push(20); t.push(21);
  t.push(29); t.push(12); t.push(28); t.push(17);
  t.push(1); t.push(15); t.push(23); t.push(26);
  t.push(5); t.push(18); t.push(31); t.push(10);
  t.push(2); t.push(8); t.push(24); t.push(14);
  t.push(32); t.push(27); t.push(3); t.push(9);
  t.push(19); t.push(13); t.push(30); t.push(6);
  t.push(22); t.push(11); t.push(4); t.push(25);
  return t;
}

/// Permuted Choice 1 (PC-1) -- FIPS 46-3 Table 3-4a.
/// Selects 56 bits from the 64-bit key, dropping the 8 parity bits.
/// PC1[i] is the source bit position (1..64) for output bit (i+1).
fn _build_pc1() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(57); t.push(49); t.push(41); t.push(33); t.push(25); t.push(17); t.push(9);
  t.push(1); t.push(58); t.push(50); t.push(42); t.push(34); t.push(26); t.push(18);
  t.push(10); t.push(2); t.push(59); t.push(51); t.push(43); t.push(35); t.push(27);
  t.push(19); t.push(11); t.push(3); t.push(60); t.push(52); t.push(44); t.push(36);
  t.push(63); t.push(55); t.push(47); t.push(39); t.push(31); t.push(23); t.push(15);
  t.push(7); t.push(62); t.push(54); t.push(46); t.push(38); t.push(30); t.push(22);
  t.push(14); t.push(6); t.push(61); t.push(53); t.push(45); t.push(37); t.push(29);
  t.push(21); t.push(13); t.push(5); t.push(28); t.push(20); t.push(12); t.push(4);
  return t;
}

/// Permuted Choice 2 (PC-2) -- FIPS 46-3 Table 3-4b.
/// Selects 48 bits from the combined 56-bit C||D key halves.
/// PC2[i] is the source bit position (1..56) for output bit (i+1).
fn _build_pc2() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(14); t.push(17); t.push(11); t.push(24); t.push(1); t.push(5);
  t.push(3); t.push(28); t.push(15); t.push(6); t.push(21); t.push(10);
  t.push(23); t.push(19); t.push(12); t.push(4); t.push(26); t.push(8);
  t.push(16); t.push(7); t.push(27); t.push(20); t.push(13); t.push(2);
  t.push(41); t.push(52); t.push(31); t.push(37); t.push(47); t.push(55);
  t.push(30); t.push(40); t.push(51); t.push(45); t.push(33); t.push(48);
  t.push(44); t.push(49); t.push(39); t.push(56); t.push(34); t.push(53);
  t.push(46); t.push(42); t.push(50); t.push(36); t.push(29); t.push(32);
  return t;
}

/// Key rotation schedule -- FIPS 46-3. Number of left-shifts applied to the
/// C and D halves per round (round 1..16).
fn _build_shifts() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(1); t.push(1); t.push(2); t.push(2); t.push(2); t.push(2); t.push(2); t.push(2);
  t.push(1); t.push(2); t.push(2); t.push(2); t.push(2); t.push(2); t.push(2); t.push(1);
  return t;
}

/// The eight standard DES S-boxes S1..S8 -- FIPS 46-3 Table 3-4.
/// Flat 512-entry table: S1 occupies indices 0..63, S2 64..127, ..., S8 448..511.
/// Each 6-bit input selects row = (bit1, bit6) and column = (bits 2..5),
/// producing a 4-bit output. These are the REAL published FIPS tables.
fn _build_sboxes() -> Vec[Int] {
  var t = Vec[Int].new();
  // S1
  t.push(14); t.push(4); t.push(13); t.push(1); t.push(2); t.push(15); t.push(11); t.push(8); t.push(3); t.push(10); t.push(6); t.push(12); t.push(5); t.push(9); t.push(0); t.push(7);
  t.push(0); t.push(15); t.push(7); t.push(4); t.push(14); t.push(2); t.push(13); t.push(1); t.push(10); t.push(6); t.push(12); t.push(11); t.push(9); t.push(5); t.push(3); t.push(8);
  t.push(4); t.push(1); t.push(14); t.push(8); t.push(13); t.push(6); t.push(2); t.push(11); t.push(15); t.push(12); t.push(9); t.push(7); t.push(3); t.push(10); t.push(5); t.push(0);
  t.push(15); t.push(12); t.push(8); t.push(2); t.push(4); t.push(9); t.push(1); t.push(7); t.push(5); t.push(11); t.push(3); t.push(14); t.push(10); t.push(0); t.push(6); t.push(13);
  // S2
  t.push(15); t.push(1); t.push(8); t.push(14); t.push(6); t.push(11); t.push(3); t.push(4); t.push(9); t.push(7); t.push(2); t.push(13); t.push(12); t.push(0); t.push(5); t.push(10);
  t.push(3); t.push(13); t.push(4); t.push(7); t.push(15); t.push(2); t.push(8); t.push(14); t.push(12); t.push(0); t.push(1); t.push(10); t.push(6); t.push(9); t.push(11); t.push(5);
  t.push(0); t.push(14); t.push(7); t.push(11); t.push(10); t.push(4); t.push(13); t.push(1); t.push(5); t.push(8); t.push(12); t.push(6); t.push(9); t.push(3); t.push(2); t.push(15);
  t.push(13); t.push(8); t.push(10); t.push(1); t.push(3); t.push(15); t.push(4); t.push(2); t.push(11); t.push(6); t.push(7); t.push(12); t.push(0); t.push(5); t.push(14); t.push(9);
  // S3
  t.push(10); t.push(0); t.push(9); t.push(14); t.push(6); t.push(3); t.push(15); t.push(5); t.push(1); t.push(13); t.push(12); t.push(7); t.push(11); t.push(4); t.push(2); t.push(8);
  t.push(13); t.push(7); t.push(0); t.push(9); t.push(3); t.push(4); t.push(6); t.push(10); t.push(2); t.push(8); t.push(5); t.push(14); t.push(12); t.push(11); t.push(15); t.push(1);
  t.push(13); t.push(6); t.push(4); t.push(9); t.push(8); t.push(15); t.push(3); t.push(0); t.push(11); t.push(1); t.push(2); t.push(12); t.push(5); t.push(10); t.push(14); t.push(7);
  t.push(1); t.push(10); t.push(13); t.push(0); t.push(6); t.push(9); t.push(8); t.push(7); t.push(4); t.push(15); t.push(14); t.push(3); t.push(11); t.push(5); t.push(2); t.push(12);
  // S4
  t.push(7); t.push(13); t.push(14); t.push(3); t.push(0); t.push(6); t.push(9); t.push(10); t.push(1); t.push(2); t.push(8); t.push(5); t.push(11); t.push(12); t.push(4); t.push(15);
  t.push(13); t.push(8); t.push(11); t.push(5); t.push(6); t.push(15); t.push(0); t.push(3); t.push(4); t.push(7); t.push(2); t.push(12); t.push(1); t.push(10); t.push(14); t.push(9);
  t.push(10); t.push(6); t.push(9); t.push(0); t.push(12); t.push(11); t.push(7); t.push(13); t.push(15); t.push(1); t.push(3); t.push(14); t.push(5); t.push(2); t.push(8); t.push(4);
  t.push(3); t.push(15); t.push(0); t.push(6); t.push(10); t.push(1); t.push(13); t.push(8); t.push(9); t.push(4); t.push(5); t.push(11); t.push(12); t.push(7); t.push(2); t.push(14);
  // S5
  t.push(2); t.push(12); t.push(4); t.push(1); t.push(7); t.push(10); t.push(11); t.push(6); t.push(8); t.push(5); t.push(3); t.push(15); t.push(13); t.push(0); t.push(14); t.push(9);
  t.push(14); t.push(11); t.push(2); t.push(12); t.push(4); t.push(7); t.push(13); t.push(1); t.push(5); t.push(0); t.push(15); t.push(10); t.push(3); t.push(9); t.push(8); t.push(6);
  t.push(4); t.push(2); t.push(1); t.push(11); t.push(10); t.push(13); t.push(7); t.push(8); t.push(15); t.push(9); t.push(12); t.push(5); t.push(6); t.push(3); t.push(0); t.push(14);
  t.push(11); t.push(8); t.push(12); t.push(7); t.push(1); t.push(14); t.push(2); t.push(13); t.push(6); t.push(15); t.push(0); t.push(9); t.push(10); t.push(4); t.push(5); t.push(3);
  // S6
  t.push(12); t.push(1); t.push(10); t.push(15); t.push(9); t.push(2); t.push(6); t.push(8); t.push(0); t.push(13); t.push(3); t.push(4); t.push(14); t.push(7); t.push(5); t.push(11);
  t.push(10); t.push(15); t.push(4); t.push(2); t.push(7); t.push(12); t.push(9); t.push(5); t.push(6); t.push(1); t.push(13); t.push(14); t.push(0); t.push(11); t.push(3); t.push(8);
  t.push(9); t.push(14); t.push(15); t.push(5); t.push(2); t.push(8); t.push(12); t.push(3); t.push(7); t.push(0); t.push(4); t.push(10); t.push(1); t.push(13); t.push(11); t.push(6);
  t.push(4); t.push(3); t.push(2); t.push(12); t.push(9); t.push(5); t.push(15); t.push(10); t.push(11); t.push(14); t.push(1); t.push(7); t.push(6); t.push(0); t.push(8); t.push(13);
  // S7
  t.push(4); t.push(11); t.push(2); t.push(14); t.push(15); t.push(0); t.push(8); t.push(13); t.push(3); t.push(12); t.push(9); t.push(7); t.push(5); t.push(10); t.push(6); t.push(1);
  t.push(13); t.push(0); t.push(11); t.push(7); t.push(4); t.push(9); t.push(1); t.push(10); t.push(14); t.push(3); t.push(5); t.push(12); t.push(2); t.push(15); t.push(8); t.push(6);
  t.push(1); t.push(4); t.push(11); t.push(13); t.push(12); t.push(3); t.push(7); t.push(14); t.push(10); t.push(15); t.push(6); t.push(8); t.push(0); t.push(5); t.push(9); t.push(2);
  t.push(6); t.push(11); t.push(13); t.push(8); t.push(1); t.push(4); t.push(10); t.push(7); t.push(9); t.push(5); t.push(0); t.push(15); t.push(14); t.push(2); t.push(3); t.push(12);
  // S8
  t.push(13); t.push(2); t.push(8); t.push(4); t.push(6); t.push(15); t.push(11); t.push(1); t.push(10); t.push(9); t.push(3); t.push(14); t.push(5); t.push(0); t.push(12); t.push(7);
  t.push(1); t.push(15); t.push(13); t.push(8); t.push(10); t.push(3); t.push(7); t.push(4); t.push(12); t.push(5); t.push(6); t.push(11); t.push(0); t.push(14); t.push(9); t.push(2);
  t.push(7); t.push(11); t.push(4); t.push(1); t.push(9); t.push(12); t.push(14); t.push(2); t.push(0); t.push(6); t.push(10); t.push(13); t.push(15); t.push(3); t.push(5); t.push(8);
  t.push(2); t.push(1); t.push(14); t.push(7); t.push(4); t.push(10); t.push(8); t.push(13); t.push(15); t.push(12); t.push(9); t.push(0); t.push(3); t.push(5); t.push(6); t.push(11);
  return t;
}

// ============================================================================
// Bit Helpers
// ============================================================================

/// Extract bit `pos` (1-indexed, MSB-first) from a 64-bit value.
/// Bit 1 is the most-significant bit; bit 64 is the least-significant bit.
fn _get_bit_64(x: Int, pos: Int) -> Int {
  return (x >> (64 - pos)) & 1;
}

/// Extract bit `pos` (1-indexed, MSB-first) from an `in_bits`-wide value.
fn _get_bit_n(x: Int, in_bits: Int, pos: Int) -> Int {
  return (x >> (in_bits - pos)) & 1;
}

/// General permutation: build `out_bits` output bits, each sourced from
/// `table[i]` (1-indexed MSB-first position within the `in_bits`-wide input).
fn _permute(input: Int, table: &Vec[Int], in_bits: Int, out_bits: Int) -> Int {
  var result = 0;
  var i = 0;
  while i < out_bits {
    let src = table[i];
    result = (result << 1) | _get_bit_n(input, in_bits, src);
    i = i + 1;
  }
  return result;
}

// ============================================================================
// Key Schedule -- FIPS 46-3
// ============================================================================

/// Derive the 16 round keys from a 64-bit key.
/// 1. PC-1 strips the 8 parity bits -> 56 bits.
/// 2. Split into C (upper 28 bits) and D (lower 28 bits).
/// 3. For each round i (0..15): left-rotate C/D by _shifts[i],
///    combine and apply PC-2 to produce the 48-bit round key.
fn _key_schedule(key64: Int, pc1: &Vec[Int], pc2: &Vec[Int], shifts: &Vec[Int]) -> Vec[Int] {
  var round_keys = Vec[Int].new();
  var pc1_out = _permute(key64, pc1, 64, 56);
  var c = (pc1_out >> 28) & 0x0FFFFFFF;
  var d = pc1_out & 0x0FFFFFFF;
  var i = 0;
  while i < 16 {
    let rot = shifts[i];
    c = ((c << rot) | (c >> (28 - rot))) & 0x0FFFFFFF;
    d = ((d << rot) | (d >> (28 - rot))) & 0x0FFFFFFF;
    let combined = (c << 28) | d;
    round_keys.push(_permute(combined, pc2, 56, 48));
    i = i + 1;
  }
  return round_keys;
}

// ============================================================================
// F-function -- the Feistel round function f(R, K)
// ============================================================================

/// f(R, K_i) = P(S(E(R) XOR K_i)).
/// 1. Expand 32-bit R to 48 bits via E.
/// 2. XOR with the 48-bit round key.
/// 3. Split into eight 6-bit groups; substitute each via S1..S8 -> 4 bits.
/// 4. Concatenate 8x4 bits and apply permutation P.
fn _f_function(r: Int, round_key: Int, e: &Vec[Int], p: &Vec[Int], sboxes: &Vec[Int]) -> Int {
  var expanded = _permute(r, e, 32, 48);
  var xored = (expanded ^ round_key) & 0xFFFFFFFFFFFF;
  var sbox_out = 0;
  var g = 0;
  while g < 8 {
    let shift = 42 - g * 6;
    let input6 = (xored >> shift) & 0x3F;
    let row = ((input6 >> 5) & 1) * 2 + (input6 & 1);
    let col = (input6 >> 1) & 0xF;
    sbox_out = (sbox_out << 4) | sboxes[g * 64 + row * 16 + col];
    g = g + 1;
  }
  return _permute(sbox_out, p, 32, 32);
}

// ============================================================================
// Core Feistel -- FIPS 46-3
// ============================================================================

/// Core 16-round Feistel. Encryption applies round keys in order K0..K15;
/// decryption applies them in reverse (K15..K0), which inverts encryption.
/// The halves are swapped after the last round before FP, per the DES spec.
fn _feistel(block: Int, round_keys: &Vec[Int], ip: &Vec[Int], fp: &Vec[Int], e: &Vec[Int], p: &Vec[Int], sboxes: &Vec[Int], decrypt: Int) -> Int {
  var state = _permute(block, ip, 64, 64);
  var left = (state >> 32) & 0xFFFFFFFF;
  var right = state & 0xFFFFFFFF;
  var round = 0;
  while round < 16 {
    var ki = round;
    if decrypt != 0 {
      ki = 15 - round;
    }
    var temp = right;
    right = (left ^ _f_function(right, round_keys[ki], e, p, sboxes)) & 0xFFFFFFFF;
    left = temp;
    round = round + 1;
  }
  var preoutput = (right << 32) | left;
  return _permute(preoutput, fp, 64, 64);
}

// ============================================================================
// Public API -- single DES blocks
// ============================================================================

/// Encrypt a single 64-bit block with DES (FIPS 46-3).
pub fn des_encrypt_block(block: Int, key: Int) -> Int {
  var ip = _build_ip();
  var fp = _build_fp();
  var e = _build_e();
  var p = _build_p();
  var sboxes = _build_sboxes();
  var pc1 = _build_pc1();
  var pc2 = _build_pc2();
  var shifts = _build_shifts();
  var round_keys = _key_schedule(key, &pc1, &pc2, &shifts);
  return _feistel(block, &round_keys, &ip, &fp, &e, &p, &sboxes, 0);
}

/// Decrypt a single 64-bit block with DES (FIPS 46-3).
pub fn des_decrypt_block(block: Int, key: Int) -> Int {
  var ip = _build_ip();
  var fp = _build_fp();
  var e = _build_e();
  var p = _build_p();
  var sboxes = _build_sboxes();
  var pc1 = _build_pc1();
  var pc2 = _build_pc2();
  var shifts = _build_shifts();
  var round_keys = _key_schedule(key, &pc1, &pc2, &shifts);
  return _feistel(block, &round_keys, &ip, &fp, &e, &p, &sboxes, 1);
}

// ============================================================================
// Triple-DES (3DES) -- EDE mode (Encrypt-Decrypt-Encrypt)
// ============================================================================

/// Encrypt a 64-bit block with Triple-DES EDE: C = E_K3(D_K2(E_K1(P))).
/// When K1 == K2 == K3 this degenerates to single DES.
pub fn des3_encrypt_block(block: Int, k1: Int, k2: Int, k3: Int) -> Int {
  var t1 = des_encrypt_block(block, k1);
  var t2 = des_decrypt_block(t1, k2);
  return des_encrypt_block(t2, k3);
}

/// Decrypt a 64-bit block with Triple-DES EDE: P = D_K1(E_K2(D_K3(C))).
pub fn des3_decrypt_block(block: Int, k1: Int, k2: Int, k3: Int) -> Int {
  var t1 = des_decrypt_block(block, k3);
  var t2 = des_encrypt_block(t1, k2);
  return des_decrypt_block(t2, k1);
}
