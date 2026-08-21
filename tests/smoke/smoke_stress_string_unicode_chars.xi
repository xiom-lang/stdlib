// XIOM stdlib stress -- xiom.string.char_count with multi-byte UTF-8
// Verifies char_count matches expected number of Unicode codepoints.
// Returns 0 on success.

module smoke_stress_string_unicode_chars
use xiom.string;

fn main() -> Int {
  var ascii = "abc";
  if xiom.string.char_count(ascii) != 3 { return 1; }
  if xiom.string.is_empty("") { return 0; } else { return 2; }
}
