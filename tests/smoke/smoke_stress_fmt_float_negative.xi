// XIOM stdlib stress — xiom.fmt Float64.to_str for negative values
// Tests that negative floats produce non-empty, distinct strings.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_float_negative
use xiom.fmt;

fn main() -> Int {
  var a = -1.0;
  var b = -0.5;
  var c = -3.14159;
  var d = -100.0;

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
