// XIOM stdlib stress -- xiom.string.str_trim whitespace removal
// Trims leading/trailing spaces from a string.
// Returns 0 on success.

module smoke_stress_string_trim
use xiom.string;

fn main() -> Int {
  var s = "  hello  ";
  if xiom.string.str_trim(s) == "hello" { return 0; } else { return 1; }
}
