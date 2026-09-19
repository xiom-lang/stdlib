// XIOM -- ChaCha20 Stream Cipher (RFC 8439)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// ChaCha20 is a fast, constant-time stream cipher designed by Daniel J. Bernstein.
// It generates a keystream by applying 20 rounds (10 double-rounds) of a
// quarter-round ARX (Add-Rotate-XOR) operation to a 512-bit state, then XORs
// that keystream with the plaintext/ciphertext. Encryption and decryption are
// identical (XOR with the same keystream).
//
// RFC 8439: https://datatracker.ietf.org/doc/html/rfc8439
//
// Security notes:
//   - The nonce MUST be unique for every message encrypted under the same key.
//     Nonce reuse completely breaks confidentiality (two-time pad).
//   - The 256-bit key provides 256-bit security against brute force.
//   - ChaCha20 has no known practical attacks when used correctly.
//   - This implementation uses constant-time operations on the state array,
//     making it resistant to timing side-channel attacks.

module xiom.chacha

// ============================================================================
// Constants -- "expand 32-byte k" as four 32-bit words (RFC 8439 Section 2.3)
//
// These four constants are placed at the beginning of the ChaCha20 state matrix.
// In ASCII: "expand 32-byte k". They serve as domain separation and
// prevent certain classes of related-key attacks.
// ============================================================================

const _CHACHA_CONST0: Int = 0x61707865; // "expa"
const _CHACHA_CONST1: Int = 0x3320646e; // "nd 3"
const _CHACHA_CONST2: Int = 0x79622d32; // "2-by"
const _CHACHA_CONST3: Int = 0x6b206574; // "te k"

// ============================================================================
// 32-bit Unsigned Helpers
//
// XIOM Int is signed 64-bit (i64). All ChaCha20 arithmetic MUST be clamped
// to 32 bits, emulating unsigned 32-bit integer operations.
// ============================================================================

/// Mask a value to the lower 32 bits (emulates u32).
fn _u32_mask(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

/// 32-bit unsigned addition (wrapping add).
fn _u32_add(a: Int, b: Int) -> Int {
  return _u32_mask(a + b);
}

/// 32-bit unsigned XOR.
fn _u32_xor(a: Int, b: Int) -> Int {
  return _u32_mask(a ^ b);
}

/// 32-bit unsigned left rotation.
/// In C: (x << n) | (x >> (32 - n))
fn _u32_rotl(x: Int, n: Int) -> Int {
  var v = _u32_mask(x);
  var left = _u32_mask(v << n);
  var right = _u32_mask(v >> (32 - n));
  return _u32_mask(left | right);
}

/// ChaCha20 State Type
/// 
/// The 512-bit state is arranged as a 4x4 matrix of 32-bit words (16 words total).
/// Layout (RFC 8439 Section 2.3):
///   state[0..3]  = constants    (row 0)
///   state[4..11] = key          (rows 1,2)
///   state[12]    = block counter (row 3, col 0)
///   state[13..15]= nonce         (row 3, cols 1-3)
pub type ChaCha20 = {
  state: Vec[Int];
}

// ============================================================================
// ChaCha20 Quarter Round (private)
//
// The core operation of ChaCha20. Operates on four 32-bit state words in-place
// using only ARX operations (Addition, Rotation, XOR).
//
// Algorithm (RFC 8439 Section 2.1):
//   1. a += b; d ^= a; d <<<= 16
//   2. c += d; b ^= c; b <<<= 12
//   3. a += b; d ^= a; d <<<= 8
//   4. c += d; b ^= c; b <<<= 7
//
// Parameters a, b, c, d are INDEXES into the state array, not values.
// The function modifies state[a], state[b], state[c], state[d] in-place.
// ============================================================================

fn _quarter_round(state: &mut Vec[Int], a: Int, b: Int, c: Int, d: Int) {
  // Round 1: column step
  state[a] = _u32_add(state[a], state[b]);
  state[d] = _u32_xor(state[d], state[a]);
  state[d] = _u32_rotl(state[d], 16);

  state[c] = _u32_add(state[c], state[d]);
  state[b] = _u32_xor(state[b], state[c]);
  state[b] = _u32_rotl(state[b], 12);

  // Round 2: diagonal step
  state[a] = _u32_add(state[a], state[b]);
  state[d] = _u32_xor(state[d], state[a]);
  state[d] = _u32_rotl(state[d], 8);

  state[c] = _u32_add(state[c], state[d]);
  state[b] = _u32_xor(state[b], state[c]);
  state[b] = _u32_rotl(state[b], 7);
}

// ============================================================================
// ChaCha20 Block Function (private)
//
// Generates one 64-byte (512-bit) keystream block from the current state.
//
// Algorithm (RFC 8439 Section 2.3):
//   1. Copy the input state (16 words) into a working array.
//   2. Apply 20 rounds (10 double-rounds) of quarter-round operations.
//      Each double-round consists of 8 quarter-rounds:
//        Column round: QR(0,4,8,12), QR(1,5,9,13), QR(2,6,10,14), QR(3,7,11,15)
//        Diagonal round: QR(0,5,10,15), QR(1,6,11,12), QR(2,7,8,13), QR(3,4,9,14)
//   3. Add the original state to the working array (word-wise, mod 2^32).
//   4. Serialize the 16 words (little-endian) into 64 output bytes.
//
// Returns: Vec[UInt8] -- 64 bytes of keystream.
// ============================================================================

fn _chacha20_block(state: &Vec[Int]) -> Vec[UInt8] {
  // Step 1: copy state into working array
  var working = Vec[Int].new();
  var i = 0;
  while i < 16 {
    working.push(state[i]);
    i = i + 1;
  }

  // Step 2: 20 rounds (10 double-rounds)
  var round = 0;
  while round < 10 {
    // Column round: operate on columns of the 4x4 matrix
    _quarter_round(&mut working, 0, 4, 8, 12);
    _quarter_round(&mut working, 1, 5, 9, 13);
    _quarter_round(&mut working, 2, 6, 10, 14);
    _quarter_round(&mut working, 3, 7, 11, 15);

    // Diagonal round: operate on diagonals of the 4x4 matrix
    _quarter_round(&mut working, 0, 5, 10, 15);
    _quarter_round(&mut working, 1, 6, 11, 12);
    _quarter_round(&mut working, 2, 7, 8, 13);
    _quarter_round(&mut working, 3, 4, 9, 14);

    round = round + 1;
  }

  // Step 3: add original state to working array (word-wise, mod 2^32)
  i = 0;
  while i < 16 {
    working[i] = _u32_add(working[i], state[i]);
    i = i + 1;
  }

  // Step 4: serialize 16 u32 words to 64 bytes (little-endian)
  var keystream = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    var w = working[i] & 0xFFFFFFFF;
    // Little-endian: LSB first
    keystream.push((w & 0xFF) as UInt8);
    w = w >> 8;
    keystream.push((w & 0xFF) as UInt8);
    w = w >> 8;
    keystream.push((w & 0xFF) as UInt8);
    w = w >> 8;
    keystream.push((w & 0xFF) as UInt8);
    i = i + 1;
  }

  return keystream;
}

// ============================================================================
// ChaCha20 Initialization
//
// Sets up the initial 512-bit state from a 256-bit key, 96-bit nonce,
// and a block counter (typically starting at 1 for encryption, 0 for
// Poly1305 key generation).
//
// State layout (16 x 32-bit words):
//   0: constant  "expa"   0x61707865
//   1: constant  "nd 3"   0x3320646e
//   2: constant  "2-by"   0x79622d32
//   3: constant  "te k"   0x6b206574
//   4-11:  key (8 words, 256 bits)
//   12:     counter (32 bits, starts at 0)
//   13-15:  nonce (3 words, 96 bits)
//
// Parameters:
//   key: 8-element Vec[Int] (each 0-255), representing a 32-byte key
//   nonce: 3-element Vec[Int] (each represents 4 little-endian bytes of the nonce)
//   counter: initial counter value (Int, 32-bit)
//   OR
//   key: Vec[Int] of 8 elements (key words as u32 values)
//   nonce: Vec[Int] of 3 elements (nonce words as u32 values)
//
// For convenience, this function accepts key and nonce as raw byte Vec[UInt8]
// arguments and handles the conversion internally.
// ============================================================================

/// Pack 4 bytes (little-endian) into a u32 word.
fn _pack_u32_le(bytes: &Vec[UInt8], offset: Int) -> Int {
  var result = 0;
  result = result | ((bytes[offset] as Int) & 0xFF);
  result = result | (((bytes[offset + 1] as Int) & 0xFF) << 8);
  result = result | (((bytes[offset + 2] as Int) & 0xFF) << 16);
  result = result | (((bytes[offset + 3] as Int) & 0xFF) << 24);
  return result & 0xFFFFFFFF;
}

/// ChaCha20 stream cipher context from a key and nonce.
pub fn chacha20_new(key: &Vec[UInt8], nonce_bytes: &Vec[UInt8]) -> ChaCha20 {
  var state = Vec[Int].new();

  // Constants (4 words)
  state.push(_CHACHA_CONST0);
  state.push(_CHACHA_CONST1);
  state.push(_CHACHA_CONST2);
  state.push(_CHACHA_CONST3);

  // Key (32 bytes -> 8 u32 words, little-endian)
  var i = 0;
  while i < 8 {
    state.push(_pack_u32_le(key, i * 4));
    i = i + 1;
  }

  // Counter (initialized to 0)
  state.push(0);

  // Nonce (12 bytes -> 3 u32 words, little-endian)
  i = 0;
  while i < 3 {
    state.push(_pack_u32_le(nonce_bytes, i * 4));
    i = i + 1;
  }

  return ChaCha20{ state: state; };
}

// ============================================================================
// ChaCha20 Encryption / Decryption
//
// ChaCha20 encryption and decryption are the same operation: XOR the
// plaintext/ciphertext with the keystream generated from the state.
//
// Algorithm (RFC 8439 Section 2.4):
//   For each 64-byte block:
//     1. Generate keystream block from current state.
//     2. Increment the block counter (state[12]).
//        If counter wraps to 0, increment state[13] (see RFC 8439 for
//        extended nonce handling; this implementation supports up to
//        2^32 blocks ~= 256 GB per message).
//     3. XOR keystream with plaintext/ciphertext.
//
// The encrypt and decrypt operations are identical since XOR is symmetric.
//
// Parameters:
//   data: plaintext or ciphertext as Vec[UInt8]
// Returns: ciphertext or plaintext as Vec[UInt8]
// ============================================================================

/// Process data through the ChaCha20 state (XOR keystream).
/// This function takes ownership of the state and consumes it.
/// For a non-consuming version, use the module-level chacha20_encrypt/chacha20_decrypt.
pub fn chacha20_process(state: &ChaCha20, data: &Vec[UInt8]) -> Vec[UInt8] {
  // Copy state so we can mutate the counter
  var st = Vec[Int].new();
  var i = 0;
  while i < 16 {
    st.push(state.state[i]);
    i = i + 1;
  }

  var result = Vec[UInt8].new();
  let data_len = data.len();
  var pos = 0;

  while pos < data_len {
    // Generate 64-byte keystream block
    var ks = _chacha20_block(&st);

    // XOR keystream with data
    var blk = 0;
    while blk < 64 && pos + blk < data_len {
      let b = (data[pos + blk] as Int) ^ (ks[blk] as Int);
      result.push((b & 0xFF) as UInt8);
      blk = blk + 1;
    }

    // Increment block counter (state[12] is the 32-bit counter)
    // - state layout: consts(0-3), key(4-11), counter(12), nonce(13-15)
    st[12] = _u32_add(st[12], 1);
    // If counter wraps, carry to state[13] (RFC 8439 S2.4: extended nonce support)
    if st[12] == 0 {
      st[13] = _u32_add(st[13], 1);
    }

    pos = pos + 64;
  }

  return result;
}

// ============================================================================
// Module-Level Convenience Functions
//
// chacha20_encrypt and chacha20_decrypt are identical functions that provide
// a stateless interface. They create a ChaCha20 state, process the data,
// and return the result.
//
// Use chacha20_encrypt for encrypting plaintext; chacha20_decrypt for
// decrypting ciphertext. Internally, both call the same XOR operation.
// ============================================================================

/// Encrypt plaintext using ChaCha20 with the given key and nonce.
/// key: 32 bytes (256 bits)
/// nonce: 12 bytes (96 bits)
/// data: plaintext to encrypt
/// Returns: ciphertext (same length as plaintext)
pub fn chacha20_encrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  var ctx = chacha20_new(key, nonce);
  return chacha20_process(&ctx, data);
}

/// Decrypt ciphertext using ChaCha20 with the given key and nonce.
/// key: 32 bytes (256 bits)
/// nonce: 12 bytes (96 bits)
/// data: ciphertext to decrypt
/// Returns: plaintext (same length as ciphertext)
/// Note: This is identical to chacha20_encrypt -- ChaCha20 is a stream cipher.
pub fn chacha20_decrypt(key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8] {
  return chacha20_encrypt(key, nonce, data);
}
