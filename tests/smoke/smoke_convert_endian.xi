// XIOM stdlib smoke test - xiom.convert.endian + xiom.convert.swap + xiom.bits.endianness
// Checks: byte-vector endian conversions, byte swaps, host endianness, and
// the bits.endianness fixed-width swaps.

module smoke_convert_endian
use xiom.convert.endian;
use xiom.convert.swap;
use xiom.bits.endianness;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var be = endian.to_be_bytes(0x0102030405060708);
  if be.len() != 8 { io.println("be len"); return 1; }
  var i = 0;
  while i < 8 {
    var b = be[i] as Int;
    if b != i + 1 { io.println("be byte"); return 2; }
    i = i + 1;
  }

  var le = endian.to_le_bytes(0x0102030405060708);
  var l0 = le[0] as Int;
  var l7 = le[7] as Int;
  if l0 != 8 || l7 != 1 { io.println("le bytes"); return 3; }

  var fbe = endian.from_be_bytes(&be);
  if fbe != 0x0102030405060708 { io.println(string.str_concat("from_be ", to_string(fbe))); return 4; }
  var fle = endian.from_le_bytes(&le);
  if fle != 0x0102030405060708 { io.println(string.str_concat("from_le ", to_string(fle))); return 5; }

  var sw = endian.swap_bytes(0x0102030405060708);
  if sw != 0x0807060504030201 { io.println(string.str_concat("swap_bytes ", to_string(sw))); return 6; }

  if !endian.is_little_endian() { io.println("endian is_le"); return 7; }

  if swap.swap16(0x0102) != 0x0201 { io.println("swap16"); return 8; }
  if swap.swap32(0x01020304) != 0x04030201 { io.println(string.str_concat("swap32 ", to_string(swap.swap32(0x01020304)))); return 9; }
  if swap.swap64(0x0102030405060708) != 0x0807060504030201 { io.println("swap64"); return 10; }

  if endianness.is_big_endian() { io.println("is_big"); return 11; }
  if !endianness.is_little_endian() { io.println("endianness is_le"); return 12; }
  if endianness.bswap_16(0x0102) != 0x0201 { io.println("bswap_16"); return 13; }
  if endianness.bswap_32(0x01020304) != 0x04030201 { io.println("bswap_32"); return 14; }
  if endianness.bswap_64(0x0102030405060708) != 0x0807060504030201 { io.println("bswap_64"); return 15; }
  if endianness.bswap_128(0x0102030405060708) != 0x0807060504030201 { io.println("bswap_128"); return 16; }
  if endianness.bswap_256(0x0102030405060708) != 0x0807060504030201 { io.println("bswap_256"); return 17; }
  if endianness.to_be(0x01020304, 4) != 0x04030201 { io.println(string.str_concat("to_be ", to_string(endianness.to_be(0x01020304, 4)))); return 18; }
  if endianness.from_be(0x04030201, 4) != 0x01020304 { io.println("from_be 4"); return 19; }
  if endianness.to_le(0x01020304, 4) != 0x01020304 { io.println("to_le"); return 20; }
  if endianness.native_to_be(0x0102030405060708) != 0x0807060504030201 { io.println("native_to_be"); return 21; }
  if endianness.native_to_le(0x0102030405060708) != 0x0102030405060708 { io.println("native_to_le"); return 22; }
  if endianness.be_to_native(0x0807060504030201) != 0x0102030405060708 { io.println("be_to_native"); return 23; }
  if endianness.le_to_native(0x0102030405060708) != 0x0102030405060708 { io.println("le_to_native"); return 24; }
  if endianness.swap_endian(0x0102030405060708) != 0x0807060504030201 { io.println("swap_endian"); return 25; }

  io.println("OK");
  return 0;
}
