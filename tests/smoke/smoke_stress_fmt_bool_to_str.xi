// XIOM stdlib stress — xiom.fmt Bool.to_str returns "true" or "false"
// Tests boolean to string conversion for both values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_bool_to_str
use xiom.fmt;

fn main() -> Int {
  var t: Bool = true;
  var f: Bool = false;

  if t.to_str() != "true" { return 1; }
  if f.to_str() != "false" { return 2; }

  return 0;
}
