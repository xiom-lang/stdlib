// XIOM stdlib smoke test - bits/bitarray, bits/bitfield, bits/bitwise,
// bits/popcount, bits/rotation.

module smoke_bits_bitarray
use xiom.bits.bitarray;
use xiom.bits.bitfield;
use xiom.bits.bitwise;
use xiom.bits.rotation;
use xiom.io;
use xiom.convert;
use xiom.string;

fn main() -> Int {
  var ba = bitarray.bit_array_new(10);
  if bitarray.bit_array_len(ba) != 10 { io.println("ba len"); return 1; }
  if bitarray.bit_array_test(ba, 2) { io.println("ba initial"); return 2; }
  bitarray.bit_array_set(&mut ba, 2);
  if !bitarray.bit_array_test(ba, 2) { io.println("ba set"); return 3; }
  if bitarray.bit_array_test(ba, 9) { io.println("ba oob"); return 4; }
  if bitarray.bit_array_count(ba) != 1 { io.println("ba count"); return 5; }
  bitarray.bit_array_clear(&mut ba, 2);
  if bitarray.bit_array_test(ba, 2) { io.println("ba clear"); return 6; }
  bitarray.bit_array_flip(&mut ba, 3);
  if !bitarray.bit_array_test(ba, 3) { io.println("ba flip"); return 7; }

  var a = bitarray.bit_array_new(8);
  bitarray.bit_array_set(&mut a, 0);
  bitarray.bit_array_set(&mut a, 7);
  var b = bitarray.bit_array_new(8);
  bitarray.bit_array_set(&mut b, 7);
  var an = bitarray.bit_array_and(a, b);
  if !bitarray.bit_array_test(an, 7) { io.println("ba and"); return 8; }
  if bitarray.bit_array_test(an, 0) { io.println("ba and2"); return 9; }
  var orr = bitarray.bit_array_or(a, b);
  if !bitarray.bit_array_test(orr, 0) || !bitarray.bit_array_test(orr, 7) { io.println("ba or"); return 10; }
  var xr = bitarray.bit_array_xor(a, b);
  if !bitarray.bit_array_test(xr, 0) { io.println("ba xor"); return 11; }
  if bitarray.bit_array_test(xr, 7) { io.println("ba xor2"); return 12; }
  var nt = bitarray.bit_array_not(a);
  if bitarray.bit_array_test(nt, 0) { io.println("ba not"); return 13; }
  if !bitarray.bit_array_test(nt, 1) { io.println("ba not2"); return 14; }
  var abytes = bitarray.bit_array_to_bytes(a);
  if abytes.len() != 1 { io.println("ba to_bytes len"); return 15; }
  var b0 = abytes[0] as Int;
  if b0 != 129 { io.println(string.str_concat("ba to_bytes ", convert.int_to_string(b0))); return 16; }

  if bitfield.bitfield_get(0xF0, 4, 4) != 0x0F { io.println(string.str_concat("bf get ", convert.int_to_string(bitfield.bitfield_get(0xF0, 4, 4)))); return 17; }
  if bitfield.bitfield_get(0x12345678, 0, 32) != 0x12345678 { io.println("bf get32"); return 18; }
  if bitfield.bitfield_set(0x0000, 4, 4, 0x0F) != 0x00F0 { io.println(string.str_concat("bf set ", convert.int_to_string(bitfield.bitfield_set(0x0000, 4, 4, 0x0F)))); return 19; }
  if bitfield.bitfield_clear(0x00F0, 4, 4) != 0 { io.println("bf clear"); return 20; }
  if bitfield.bitfield_sign_extend(0x80, 8) != -128 { io.println(string.str_concat("bf signext ", convert.int_to_string(bitfield.bitfield_sign_extend(0x80, 8)))); return 21; }
  if bitfield.bitfield_mask(8) != 255 { io.println("bf mask"); return 22; }
  if bitfield.bitfield_mask(64) != -1 { io.println("bf mask64"); return 23; }
  if bitfield.bitfield_extract_u(0x00F0, 4, 4) != 0x0F { io.println("bf extract"); return 24; }
  if bitfield.bitfield_insert(0, 0x0F, 4, 4) != 0x00F0 { io.println("bf insert"); return 25; }

  if bitwise.popcnt(0xF0) != 4 { io.println(string.str_concat("popcnt ", convert.int_to_string(bitwise.popcnt(0xF0)))); return 26; }
  if bitwise.popcnt(-1) != 64 { io.println("popcnt -1"); return 27; }
  if bitwise.clz(1) != 63 { io.println(string.str_concat("clz ", convert.int_to_string(bitwise.clz(1)))); return 28; }
  if bitwise.clz(0) != 64 { io.println("clz 0"); return 29; }
  if bitwise.ctz(16) != 4 { io.println("ctz"); return 30; }
  if bitwise.bit_reverse(1) != -9223372036854775808 { io.println("bit_reverse"); return 31; }
  if bitwise.bit_reverse_byte(0x01) != 0x80 { io.println(string.str_concat("bit_reverse_byte ", convert.int_to_string(bitwise.bit_reverse_byte(0x01)))); return 32; }
  if bitwise.byte_swap(0x0102030405060708) != 0x0807060504030201 { io.println("byte_swap"); return 33; }
  if bitwise.rotate_left(1, 1) != 2 { io.println("bw rot_left"); return 34; }
  if bitwise.rotate_right(2, 1) != 1 { io.println("bw rot_right"); return 35; }
  if bitwise.rotate_left(1, 65) != 2 { io.println("bw rot_left wrap"); return 36; }
  if bitwise.bit_width(255) != 8 { io.println(string.str_concat("bit_width ", convert.int_to_string(bitwise.bit_width(255)))); return 37; }
  if bitwise.bit_length(0) != 0 { io.println("bit_length 0"); return 38; }
  if bitwise.leading_ones(0xF000000000000000) != 4 { io.println(string.str_concat("leading_ones ", convert.int_to_string(bitwise.leading_ones(0xF000000000000000)))); return 39; }
  if bitwise.trailing_ones(7) != 3 { io.println("trailing_ones"); return 40; }
  if bitwise.bit_parity(3) != 0 { io.println("parity 3"); return 41; }
  if bitwise.bit_parity(1) != 1 { io.println("parity 1"); return 42; }
  if bitwise.bit_scan_forward(16) != 4 { io.println("bsf"); return 43; }
  if bitwise.bit_scan_forward(0) != -1 { io.println("bsf 0"); return 44; }
  if bitwise.bit_scan_reverse(0x80) != 7 { io.println("bsr"); return 45; }
  if !bitwise.is_power_of_two_bit(16) { io.println("pow2"); return 46; }
  if bitwise.is_power_of_two_bit(15) { io.println("pow2 bad"); return 47; }

  // NOTE: xiom.bits.popcount is covered separately in smoke_bits_popcount.xi —
  // its module name collides with bitwise's `popcount` function when both are
  // imported into one file.

  if rotation.rotate_left(1, 1) != 2 { io.println("rot rotl"); return 61; }
  if rotation.rotate_right(2, 1) != 1 { io.println("rot rotr"); return 62; }
  var rc = rotation.rotate_left_carry(0x8000000000000000, 1, 1);
  if rc.0 != 1 { io.println(string.str_concat("rcl ", convert.int_to_string(rc.0))); return 63; }
  if rc.1 != 1 { io.println("rcl carry"); return 64; }
  var rc2 = rotation.rotate_right_carry(1, 1, 0);
  if rc2.0 != 0 { io.println("rcr"); return 65; }
  if rc2.1 != 1 { io.println("rcr carry"); return 66; }
  if rotation.rol_imm(1, 1) != 2 { io.println("rol_imm"); return 67; }
  if rotation.ror_imm(2, 1) != 1 { io.println("ror_imm"); return 68; }
  if rotation.bit_rotate_left(1, 1) != 2 { io.println("bit_rotate_left"); return 69; }
  if rotation.bit_rotate_right(2, 1) != 1 { io.println("bit_rotate_right"); return 70; }
  if rotation.masked_rotate_left(5, 1, 7) != 3 { io.println("masked_rotl"); return 71; }
  if rotation.masked_rotate_right(3, 1, 7) != 5 { io.println("masked_rotr"); return 72; }

  io.println("OK");
  return 0;
}
