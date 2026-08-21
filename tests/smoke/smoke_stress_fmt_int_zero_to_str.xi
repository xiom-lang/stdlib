// XIOM stdlib stress -- xiom.fmt Int.to_str for zero
// Tests that zero is formatted as "0", not " " or empty.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_int_zero_to_str
use xiom.fmt;

fn main() -> Int {
  var a: Int = 0;
  var b: Int = 0;

  if a.to_str() != "0" { return 1; }
  if b.to_str() != "0" { return 2; }

  var s = a.to_str();
  if s.len() != 1 { return 3; }

  return 0;
}
