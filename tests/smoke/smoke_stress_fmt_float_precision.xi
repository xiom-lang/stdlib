// XIOM stdlib stress -- xiom.fmt Float64.to_str precision handling
// Tests that floats with many decimal digits produce non-empty strings.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_float_precision
use xiom.fmt;

fn main() -> Int {
  var a = 3.141592653589793;
  var b = 2.718281828459045;
  var c = 1.4142135623730951;
  var d = 0.1234567890123456;

  var sa = a.to_str();
  var sb = b.to_str();
  var sc = c.to_str();
  var sd = d.to_str();

  if sa.len() == 0 { return 1; }
  if sb.len() == 0 { return 2; }
  if sc.len() == 0 { return 3; }
  if sd.len() == 0 { return 4; }

  return 0;
}
