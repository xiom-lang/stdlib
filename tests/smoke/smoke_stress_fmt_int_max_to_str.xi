// XIOM stdlib stress — xiom.fmt Int.to_str for large positive boundary values
// Tests integer to string for values near max and powers of two.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_int_max_to_str
use xiom.fmt;

fn main() -> Int {
  var a: Int = 2147483647;
  var b: Int = 1073741824;
  var c: Int = 536870912;
  var d: Int = 65536;

  if a.to_str().len() == 0 { return 1; }
  if b.to_str().len() == 0 { return 2; }
  if c.to_str().len() == 0 { return 3; }
  if d.to_str().len() == 0 { return 4; }

  var s = a.to_str();
  if s.len() < 9 { return 5; }

  return 0;
}
