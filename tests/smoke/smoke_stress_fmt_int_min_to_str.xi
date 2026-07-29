// XIOM stdlib stress — xiom.fmt Int.to_str for negative boundary values
// Tests integer to string for negative values including near-min.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_int_min_to_str
use xiom.fmt;

fn main() -> Int {
  var a: Int = -1;
  var b: Int = -42;
  var c: Int = -100;
  var d: Int = -99999;
  var e: Int = -2147483648;

  if a.to_str() != "-1" { return 1; }
  if b.to_str() != "-42" { return 2; }
  if c.to_str() != "-100" { return 3; }
  if d.to_str() != "-99999" { return 4; }

  var s = e.to_str();
  if s.len() < 10 { return 5; }

  return 0;
}
