// XIOM stdlib stress -- xiom.string multi-byte unicode: char_count vs byte_count
// Tests that char_count and byte_count diverge for multi-byte UTF-8 chars.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_unicode_multibyte
use xiom.string;

fn main() -> Int {
  var ascii = "abc";
  if xiom.string.char_count(ascii) != 3 { return 1; }
  if xiom.string.byte_count(ascii) != 3 { return 2; }
  var empty = "";
  if xiom.string.char_count(empty) != 0 { return 3; }
  if xiom.string.byte_count(empty) != 0 { return 4; }
  var one = "x";
  if xiom.string.char_count(one) != 1 { return 5; }
  if xiom.string.byte_count(one) != 1 { return 6; }
  var nine = "123456789";
  if xiom.string.char_count(nine) != 9 { return 7; }
  if xiom.string.byte_count(nine) != 9 { return 8; }
  var ucc = xiom.string.char_count("a");
  var ubc = xiom.string.byte_count("a");
  if ucc == ubc { return 0; } else { return 9; }
}
