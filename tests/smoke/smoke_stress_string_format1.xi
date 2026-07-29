// XIOM stdlib stress — xiom.string.format1 with one arg
// Tests format with one placeholder and a single replacement value.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_format1
use xiom.string;

fn main() -> Int {
  var result = xiom.string.format1("value is {}", 42);
  if result == "value is 42" { return 0; } else { return 1; }
}
