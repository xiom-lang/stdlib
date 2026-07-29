// XIOM stdlib stress — xiom.fmt Float64.to_str for zero values
// Tests that 0.0 produces a non-empty, sane representation.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_float_zero
use xiom.fmt;

fn main() -> Int {
  var a = 0.0;
  var b = 0.0;

  var sa = a.to_str();
  var sb = b.to_str();

  if sa.len() == 0 { return 1; }
  if sb.len() == 0 { return 2; }

  return 0;
}
