// XIOM stdlib stress — xiom.fmt Float64.to_str for common values
// Tests float to string conversion for round and fractional values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_float_to_str
use xiom.fmt;

fn main() -> Int {
  var a = 0.0;
  var b = 1.0;
  var c = 3.14;
  var d = 0.5;
  var e = 100.0;

  if a.to_str().len() == 0 { return 1; }
  if b.to_str().len() == 0 { return 2; }
  if c.to_str().len() == 0 { return 3; }
  if d.to_str().len() == 0 { return 4; }
  if e.to_str().len() == 0 { return 5; }

  return 0;
}
