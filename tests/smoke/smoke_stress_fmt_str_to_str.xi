// XIOM stdlib stress — xiom.fmt Str.to_str identity round-trip
// Tests string to_str returns itself for various inputs.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_str_to_str
use xiom.fmt;

fn main() -> Int {
  var a = "hello";
  var b = "";
  var c = "multi\nline\ttext";
  var d = "   spaces   ";

  if a.to_str() != a { return 1; }
  if b.to_str() != b { return 2; }
  if c.to_str() != c { return 3; }
  if d.to_str() != d { return 4; }

  return 0;
}
