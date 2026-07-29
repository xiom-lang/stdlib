// XIOM stdlib stress — xiom.fmt Int.to_str for positive values
// Tests integer to string conversion for common positive values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_int_to_str
use xiom.fmt;

fn main() -> Int {
  var a: Int = 0;
  var b: Int = 1;
  var c: Int = 42;
  var d: Int = 100;
  var e: Int = 9999;
  var f: Int = 1000000;

  if a.to_str() != "0" { return 1; }
  if b.to_str() != "1" { return 2; }
  if c.to_str() != "42" { return 3; }
  if d.to_str() != "100" { return 4; }
  if e.to_str() != "9999" { return 5; }
  if f.to_str() != "1000000" { return 6; }

  return 0;
}
