// p_wave161_shapes.xi -- wave 161 lock: the fix-first defect batch from the
// packages wishlist (fix-first candidates) plus the bits.rotation finding:
//   (a) string.builder.sb_push_int(INT_MIN) emitted just "-" (negate-in-place);
//   (b) convert.parse.parse_int rejected the INT64_MIN magnitude (positive
//       accumulation);
//   (c) crypto.hash _u64_lshr/_u64_shr divided by _pow2(63) = INT64_MIN for
//       n = 63 and over-corrected (MIN -> 3 instead of 1) -- now fixed and
//       exposed as the pub u64_lshr/u64_rotr helpers;
//   (d) bits.rotation.rotate_left/rotate_right relied on `>>` alone (arithmetic
//       for negative operands): rotate_right(MIN,1) was 0xC000... instead of
//       0x4000..., rotate_left(MIN,1) was -1 instead of 1; rotate_right_carry
//       OR-ed a stale sign bit over carry_in 0.
// Pre-fix evidence: the recon scratch (out/w161_recon2.xi) returned 123
// (rows 1+2+8+16+32+64 fail) on the official v0.64.5 pin.
// Rows (0 = all hold):
//  1 -- sb_push_int(INT_MIN) is "-9223372036854775808"
//  2 -- sb_push_int regression: 0/-7/42/INT_MAX/INT_MIN+1
//  3 -- parse_int("-9223372036854775808") is Ok(INT_MIN)
//  4 -- parse_int("-9223372036854775809") stays Err (overflow honest)
//  5 -- parse_int regression: INT_MAX, +2^63 Err, "+42", "-0", "0042"
//  6 -- parse_int_radix(radix 16) INT_MIN magnitude + radix guard
//  7 -- u64_lshr: n=63, n=1, -1>>1, 0/64 guards, -2>>2
//  8 -- u64_rotr: MIN rotr 63 -> 1; rotr(1,1) -> MIN; rotr(-2,1) -> INT_MAX;
//       rotr(MIN,1) -> 2^62; n 0/64 identity
//  9 -- rotate_left: MIN/1 -> 1; -2/1 -> -3; 1/1 -> 2; 1/-1 -> MIN; k=0
// 10 -- rotate_right: MIN/1 -> 2^62; -2/1 -> INT_MAX; 2/1 -> 1; MIN/63 -> 1
// 11 -- rotate_right_carry: (MIN,1,0) -> (2^62,0); (0,1,1) -> (MIN,0);
//       (1,1,0) -> (0,1)
// 12 -- rotate_left_carry: (MIN,1,0) -> (0,1); (1,1,0) -> (2,0)
// 13 -- masked rotations regression: mask 0b1010 left/right + k=0 identity
// 14 -- BLAKE2b-512("abc") RFC 7693 KAT (exercises rotr 63 in the live path)
// 15 -- SHA-512("abc") FIPS KAT (exercises the rewritten 64-bit helpers)
// Setup failures use 20+.

module p_wave161_shapes

use xiom.string.builder;
use xiom.convert.parse;
use xiom.bits.rotation;
use xiom.crypto.hash as h;
use xiom.encoding.hex;
use xiom.core;

fn abc3() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(97 as UInt8);
  v.push(98 as UInt8);
  v.push(99 as UInt8);
  return v;
}

fn main() -> Int {
  // Row 1: sb_push_int(INT_MIN).
  var sb = Vec[UInt8].new();
  builder.sb_push_int(&mut sb, core.INT_MIN);
  if builder.sb_to_str(&sb) != "-9223372036854775808" { return 1; }

  // Row 2: sb_push_int regression set.
  var sb2 = Vec[UInt8].new();
  builder.sb_push_int(&mut sb2, 0);
  if builder.sb_to_str(&sb2) != "0" { return 2; }
  builder.sb_push_int(&mut sb2, 0 - 7);
  if builder.sb_to_str(&sb2) != "0-7" { return 2; }
  var sb2b = Vec[UInt8].new();
  builder.sb_push_int(&mut sb2b, 42);
  if builder.sb_to_str(&sb2b) != "42" { return 2; }
  var sb2c = Vec[UInt8].new();
  builder.sb_push_int(&mut sb2c, core.INT_MAX);
  if builder.sb_to_str(&sb2c) != "9223372036854775807" { return 2; }
  var sb2d = Vec[UInt8].new();
  builder.sb_push_int(&mut sb2d, core.INT_MIN + 1);
  if builder.sb_to_str(&sb2d) != "-9223372036854775807" { return 2; }

  // Row 3: parse_int(INT_MIN).
  match parse.parse_int("-9223372036854775808") {
    Ok(v) => { if v != core.INT_MIN { return 3; } },
    Err(_) => { return 3; },
  }

  // Row 4: one below INT_MIN stays Err.
  match parse.parse_int("-9223372036854775809") {
    Ok(_) => { return 4; },
    Err(_) => {},
  }

  // Row 5: parse_int regression set.
  match parse.parse_int("9223372036854775807") {
    Ok(v) => { if v != core.INT_MAX { return 5; } },
    Err(_) => { return 5; },
  }
  match parse.parse_int("9223372036854775808") {
    Ok(_) => { return 5; },
    Err(_) => {},
  }
  match parse.parse_int("+42") {
    Ok(v) => { if v != 42 { return 5; } },
    Err(_) => { return 5; },
  }
  match parse.parse_int("-0") {
    Ok(v) => { if v != 0 { return 5; } },
    Err(_) => { return 5; },
  }
  match parse.parse_int("0042") {
    Ok(v) => { if v != 42 { return 5; } },
    Err(_) => { return 5; },
  }

  // Row 6: radix 16 INT_MIN magnitude + radix guard.
  match parse.parse_int_radix("-8000000000000000", 16) {
    Ok(v) => { if v != core.INT_MIN { return 6; } },
    Err(_) => { return 6; },
  }
  match parse.parse_int_radix("-8000000000000001", 16) {
    Ok(_) => { return 6; },
    Err(_) => {},
  }
  match parse.parse_int_radix("ff", 1) {
    Ok(_) => { return 6; },
    Err(_) => {},
  }

  // Row 7: u64_lshr.
  if h.u64_lshr(core.INT_MIN, 63) != 1 { return 7; }
  if h.u64_lshr(0 - 1, 1) != core.INT_MAX { return 7; }
  if h.u64_lshr(core.INT_MIN, 1) != 4611686018427387904 { return 7; }
  if h.u64_lshr(5, 0) != 5 { return 7; }
  if h.u64_lshr(5, 64) != 0 { return 7; }
  if h.u64_lshr(0 - 2, 2) != 4611686018427387903 { return 7; }

  // Row 8: u64_rotr.
  if h.u64_rotr(core.INT_MIN, 63) != 1 { return 8; }
  if h.u64_rotr(1, 1) != core.INT_MIN { return 8; }
  if h.u64_rotr(0 - 2, 1) != core.INT_MAX { return 8; }
  if h.u64_rotr(core.INT_MIN, 1) != 4611686018427387904 { return 8; }
  if h.u64_rotr(7, 0) != 7 { return 8; }
  if h.u64_rotr(7, 64) != 7 { return 8; }

  // Row 9: rotate_left.
  if rotation.rotate_left(core.INT_MIN, 1) != 1 { return 9; }
  if rotation.rotate_left(0 - 2, 1) != (0 - 3) { return 9; }
  if rotation.rotate_left(1, 1) != 2 { return 9; }
  if rotation.rotate_left(1, 0 - 1) != core.INT_MIN { return 9; }
  if rotation.rotate_left(7, 0) != 7 { return 9; }
  if rotation.rotate_left(7, 64) != 7 { return 9; }

  // Row 10: rotate_right.
  if rotation.rotate_right(core.INT_MIN, 1) != 4611686018427387904 { return 10; }
  if rotation.rotate_right(0 - 2, 1) != core.INT_MAX { return 10; }
  if rotation.rotate_right(2, 1) != 1 { return 10; }
  if rotation.rotate_right(core.INT_MIN, 63) != 1 { return 10; }
  if rotation.rotate_right(7, 0) != 7 { return 10; }
  if rotation.rotate_right(7, 64) != 7 { return 10; }

  // Row 11: rotate_right_carry.
  let rc1 = rotation.rotate_right_carry(core.INT_MIN, 1, 0);
  if rc1.0 != 4611686018427387904 { return 11; }
  if rc1.1 != 0 { return 11; }
  let rc2 = rotation.rotate_right_carry(0, 1, 1);
  if rc2.0 != core.INT_MIN { return 11; }
  if rc2.1 != 0 { return 11; }
  let rc3 = rotation.rotate_right_carry(1, 1, 0);
  if rc3.0 != 0 { return 11; }
  if rc3.1 != 1 { return 11; }

  // Row 12: rotate_left_carry.
  let lc1 = rotation.rotate_left_carry(core.INT_MIN, 1, 0);
  if lc1.0 != 0 { return 12; }
  if lc1.1 != 1 { return 12; }
  let lc2 = rotation.rotate_left_carry(1, 1, 0);
  if lc2.0 != 2 { return 12; }
  if lc2.1 != 0 { return 12; }

  // Row 13: masked rotations regression (positive fold).
  if rotation.masked_rotate_left(2, 1, 10) != 8 { return 13; }
  if rotation.masked_rotate_right(8, 1, 10) != 2 { return 13; }
  if rotation.masked_rotate_left(5, 0, 10) != 5 { return 13; }

  // Row 14: BLAKE2b-512("abc") RFC 7693 KAT.
  let b2 = h.crypto_hash_blake2b(&abc3());
  if b2.len() != 64 { return 14; }
  if hex.hex_encode(&b2) != "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923" { return 14; }

  // Row 15: SHA-512("abc") FIPS KAT.
  let s5 = h.crypto_hash_sha512(&abc3());
  if s5.len() != 64 { return 15; }
  if hex.hex_encode(&s5) != "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f" { return 15; }

  return 0;
}
