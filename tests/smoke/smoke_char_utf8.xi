module smoke_char_utf8
use xiom.char;

fn main() -> Int {
  if char.len_utf8('A') != 1 { return 1; }
  if char.len_utf8('\t') != 1 { return 2; }

  if char.len_utf8(to_char(0x80)) != 2 { return 3; }
  if char.len_utf8(to_char(0x7FF)) != 2 { return 4; }

  if char.len_utf8(to_char(0x800)) != 3 { return 5; }
  if char.len_utf8(to_char(0xFFFF)) != 3 { return 6; }

  if char.len_utf8(to_char(0x10000)) != 4 { return 7; }

  var buf = Vec[UInt8].new();
  char.encode_utf8('A', &mut buf);
  if buf.len() != 1 { return 8; }
  if buf[0] != 65 as UInt8 { return 9; }

  var buf2 = Vec[UInt8].new();
  char.encode_utf8(to_char(0x80), &mut buf2);
  if buf2.len() != 2 { return 10; }

  return 0;
}
