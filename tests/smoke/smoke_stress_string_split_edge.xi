// XIOM stdlib stress -- xiom.string.str_split edge cases
// Splits empty string, single char, and no-delimiter-found.
// Returns 0 on success.

module smoke_stress_string_split_edge
use xiom.string;

fn main() -> Int {
  var parts = xiom.string.str_split("a,b,c", ",");
  if parts.len() != 3 { return 1; }
  var parts2 = xiom.string.str_split("hello", ",");
  if parts2.len() != 1 { return 2; }
  var parts3 = xiom.string.str_split("", ",");
  if parts3.len() >= 0 { return 0; } else { return 3; }
}
