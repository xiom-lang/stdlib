// XIOM stdlib smoke test - xiom.bits.popcount
// Separate file because the `popcount` module name collides with bitwise's
// `popcount` function when both are imported together.

module smoke_bits_popcount
use xiom.bits.popcount;
use xiom.io;
use xiom.convert;
use xiom.string;

fn main() -> Int {
  if popcount.popcount(0xF0) != 4 { io.println(string.str_concat("popcount ", convert.int_to_string(popcount.popcount(0xF0)))); return 1; }
  if popcount.popcount(-1) != 64 { io.println("popcount -1"); return 2; }
  var u: UInt64 = 0xFF00FF00;
  if popcount.popcount64(u) != 16 { io.println(string.str_concat("popcount64 ", convert.int_to_string(popcount.popcount64(u)))); return 3; }
  if popcount.count_leading_zeros(1) != 63 { io.println("clz"); return 4; }
  if popcount.count_leading_zeros(0) != 64 { io.println("clz 0"); return 5; }
  if popcount.count_trailing_zeros(16) != 4 { io.println("ctz"); return 6; }
  if popcount.count_ones(0xF0) != 4 { io.println("ones"); return 7; }
  if popcount.count_zeros(0) != 64 { io.println("zeros"); return 8; }
  if popcount.parity(1) != 1 { io.println("parity"); return 9; }
  if popcount.parity(3) != 0 { io.println("parity 3"); return 10; }
  if popcount.bit_length(255) != 8 { io.println("bit_length"); return 11; }
  if popcount.bit_length(0) != 0 { io.println("bit_length 0"); return 12; }
  if popcount.next_pow2(5) != 8 { io.println(string.str_concat("next_pow2 ", convert.int_to_string(popcount.next_pow2(5)))); return 13; }
  if popcount.next_pow2(8) != 8 { io.println("next_pow2 exact"); return 14; }
  if popcount.next_pow2(0) != 1 { io.println("next_pow2 zero"); return 15; }
  if popcount.prev_pow2(5) != 4 { io.println("prev_pow2"); return 16; }
  if popcount.prev_pow2(1) != 1 { io.println("prev_pow2 one"); return 17; }
  if popcount.rotate_left(1, 1) != 2 { io.println("rotl"); return 18; }
  if popcount.rotate_right(2, 1) != 1 { io.println("rotr"); return 19; }
  if popcount.rotate_left(1, 65) != 2 { io.println("rotl wrap"); return 20; }

  io.println("OK");
  return 0;
}
