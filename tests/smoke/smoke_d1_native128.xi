// D1 smoke: native Int128/UInt128/Float128 primitives
// Returns 0 on success, nonzero on failure.
use xiom.num;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // --- Int128 arithmetic ---
  var a: Int128 = 100 as Int128;
  var b: Int128 = 7 as Int128;
  if a + b != (107 as Int128) { return 1; }
  if a - b != (93 as Int128) { return 2; }
  if a / b != (14 as Int128) { return 3; }
  if a % b != (2 as Int128) { return 4; }
  if (14 as Int128) * b != (98 as Int128) { return 5; }

  // --- Int128 beyond i64 range ---
  var big: Int128 = 9223372036854775808 as Int128; // 2^63
  var big2 = big + big; // 2^64
  if big2 != (18446744073709551616 as Int128) { return 6; }
  if big2 / (2 as Int128) != big { return 7; }
  if big2 % (2 as Int128) != (0 as Int128) { return 8; }

  // --- Int128 string round-trip ---
  var s = num.i128_to_str(big2);
  if s != "18446744073709551616" { return 9; }
  var parsed = num.i128_from_str(s);
  match parsed {
    Ok(v) => { if v != big2 { return 10; } }
    Err(_) => { return 10; }
  }
  var neg = num.i128_to_str(0 as Int128 - big);
  if neg != "-9223372036854775808" { return 11; }

  // --- UInt128: true 128-bit wrap ---
  var ua: UInt128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF as UInt128;
  var ub: UInt128 = 2 as UInt128;
  if ua + ub != (1 as UInt128) { return 12; } // 2^128-1 + 2 wraps to 1
  var ubig: UInt128 = 18446744073709551616 as UInt128; // 2^64
  if ubig / ub != (9223372036854775808 as UInt128) { return 13; }
  if ubig % ub != (0 as UInt128) { return 14; }

  // --- Float128 ---
  var fa: Float128 = 1.5 as Float128;
  var fb: Float128 = 2.0 as Float128;
  if fa * fb != (3.0 as Float128) { return 15; }
  if fa / fb != (0.75 as Float128) { return 16; }
  if fa + fb != (3.5 as Float128) { return 17; }
  if fb - fa != (0.5 as Float128) { return 18; }

  // --- Int128 <-> Int conversions ---
  var i = 42;
  var i2i128: Int128 = i as Int128;
  if i2i128 != (42 as Int128) { return 19; }
  var back: Int = i2i128 as Int;
  if back != 42 { return 20; }

  // --- Int128 comparisons ---
  var lo: Int128 = 1 as Int128;
  var hi: Int128 = 2 as Int128;
  if !(lo < hi) { return 21; }
  if !(hi > lo) { return 22; }
  if lo == hi { return 23; }
  if num.i128_compare(lo, hi) != -1 { return 24; }
  if num.i128_compare(hi, lo) != 1 { return 25; }
  if num.i128_compare(hi, hi) != 0 { return 26; }

  return 0;
}
