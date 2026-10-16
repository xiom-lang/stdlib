// p_wave168_shapes.xi -- wave 168 locks: Keccak-256 (wishlist row 25) and
// FNV-1a over Str + masked combine (row 34); ZIP container read/write
// (row 22, xiom.compress.zip) extends this probe in the same wave.
//
// Keccak-256 provenance: all digests cross-checked 2026-10-16 against
// pycryptodome 3.24.1 Crypto.Hash.keccak digest_bits=256 (the 0x01-padding
// original-Keccak/Ethereum variant, NOT FIPS 202 SHA3-256). The empty and
// "abc" answers are the well-known Ethereum keccak256 values. The 136/137/
// 1000-byte messages carry bytes (i*7 + 3) mod 256 (rate-boundary, one-past-
// boundary and multi-block paths).
//
// FNV provenance: fnv1a32/fnv1a64 values computed with the reference FNV
// algorithm (offset 0x811C9DC5 / 0xCBF29CE484222325, prime 0x01000193 /
// 0x100000001B3) and cross-checked in Python; the Str variants must be
// byte-exact with the Vec[UInt8] variants of the same input.
//
// Rows (0 = all hold):
//  1 -- keccak256("") KAT: c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
//  2 -- keccak256("abc") KAT: 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
//  3 -- keccak256 136B pattern (exactly one rate block)
//  4 -- keccak256 137B pattern (block + 1-byte tail; tail-pad boundary)
//  5 -- keccak256 1000B pattern (multi-block) + digest length 32, hex 64
//  6 -- fnv1a_str("") offset basis; "hello"/"abc"/fox vectors
//  7 -- fnv1a_str byte-parity with fnv1a32 over the same bytes
//  8 -- fnv1a64_str vectors + byte-parity with fnv1a64
//  9 -- fnv1a_combine_masked: bits<=0 -> 0; bits 16/1 truncate; bits 64 == combine_hashes; order-dependent
// Setup failures use 20+.

module p_wave168_shapes

use xiom.crypto.keccak;
use xiom.hash;
use xiom.encoding.hex;

fn bytes_pattern(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    var b = (i * 7 + 3) % 256;
    v.push(b as UInt8);
    i = i + 1;
  }
  return v;
}

fn _raw_u8(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

fn ascii_bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  let len = s.len();
  let base = s.c_str();
  while i < len {
    v.push(_raw_u8(base, i));
    i = i + 1;
  }
  return v;
}

fn hex_of(data: &Vec[UInt8]) -> Str {
  return hex.hex_encode(data);
}

fn main() -> Int {
  // Row 1: keccak256("") KAT.
  var empty = Vec[UInt8].new();
  var h_empty = keccak.keccak256_hex(&empty);
  if h_empty != "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" { return 1; }

  // Row 2: keccak256("abc") KAT.
  var abc = ascii_bytes("abc");
  var h_abc = keccak.keccak256_hex(&abc);
  if h_abc != "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45" { return 2; }

  // Row 3: exactly one rate block (136 bytes).
  var m136 = bytes_pattern(136);
  let h136 = keccak.keccak256_hex(&m136);
  if h136 != "742061bcad767ed4c4f5883b1dcb1aad11afdcc140dc469d953759b127b9f9ed" { return 3; }

  // Row 4: one block plus a one-byte tail.
  var m137 = bytes_pattern(137);
  let h137 = keccak.keccak256_hex(&m137);
  if h137 != "e3371f61e770abf254c34239c3b0099ad90594507415bc81dd0a10b9692bbf2a" { return 4; }

  // Row 5: multi-block + shape.
  var m1000 = bytes_pattern(1000);
  let h1000 = keccak.keccak256_hex(&m1000);
  if h1000 != "80cdc8dd52cbb3dbaea8f383209893fa2bb52efbd5aedbb4b26dcfe307fcdc9b" { return 5; }
  let d1000 = keccak.keccak256(&m1000);
  if d1000.len() != 32 { return 5; }
  if h1000.len() != 64 { return 5; }

  // Row 6: FNV-1a 32 over Str.
  if hash.fnv1a_str("") != 0x811C9DC5 { return 6; }
  if hash.fnv1a_str("hello") != 0x4F9F2CAB { return 6; }
  if hash.fnv1a_str("abc") != 0x1A47E90B { return 6; }
  if hash.fnv1a_str("the quick brown fox jumps over the lazy dog") != 0xEF693FF0 { return 6; }

  // Row 7: Str variant is byte-exact with the Vec variant.
  var hello_b = ascii_bytes("hello");
  let v32 = hash.fnv1a32(&hello_b);
  let s32 = hash.fnv1a_str("hello");
  if v32 != s32 { return 7; }
  var abc_b = ascii_bytes("abc");
  let v32b = hash.fnv1a32(&abc_b);
  let s32b = hash.fnv1a_str("abc");
  if v32b != s32b { return 7; }
  let v32c = hash.fnv1a32(&empty);
  let s32c = hash.fnv1a_str("");
  if v32c != s32c { return 7; }

  // Row 8: FNV-1a 64 over Str.
  if hash.fnv1a64_str("") != 0xCBF29CE484222325 { return 8; }
  if hash.fnv1a64_str("hello") != 0xA430D84680AABD0B { return 8; }
  if hash.fnv1a64_str("abc") != 0xE71FA2190541574B { return 8; }
  var fox_b = ascii_bytes("the quick brown fox jumps over the lazy dog");
  let v64 = hash.fnv1a64(&fox_b);
  let s64 = hash.fnv1a64_str("the quick brown fox jumps over the lazy dog");
  if v64 != s64 { return 8; }

  // Row 9: masked combine.
  let a = 0x12345678;
  let b = 0x0BADF00D;
  let full = hash.fnv1a_combine_masked(a, b, 64);
  let reference = hash.combine_hashes(a, b);
  if full != reference { return 9; }
  let m16 = hash.fnv1a_combine_masked(a, b, 16);
  if m16 < 0 || m16 >= 65536 { return 9; }
  let m16_ref = reference & 0xFFFF;
  if m16 != m16_ref { return 9; }
  let m1 = hash.fnv1a_combine_masked(a, b, 1);
  let m1_ref = reference & 1;
  if m1 != m1_ref { return 9; }
  if hash.fnv1a_combine_masked(a, b, 0) != 0 { return 9; }
  if hash.fnv1a_combine_masked(a, b, 0 - 3) != 0 { return 9; }
  let swapped = hash.fnv1a_combine_masked(b, a, 64);
  if swapped == full { return 9; }

  return 0;
}
