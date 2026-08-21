// XIOM stdlib stress -- xiom.string.char_count / byte_count
// Tests character vs byte counts (same for ASCII, different for multi-byte).
// Returns 0 on success.

module smoke_stress_string_char_count
use xiom.string;

fn main() -> Int {
  var s = "hello";
  if xiom.string.char_count(s) == 5 && xiom.string.byte_count(s) == 5 {
    return 0;
  }
  return 1;
}
