module smoke_fmt_display
use xiom.fmt;

fn main() -> Int {
  var n: Int = 99;
  if n.to_str() != "99" { return 1; }

  var f: Float64 = 2.5;
  if f.to_str() == "" { return 2; }

  var b: Bool = true;
  if b.to_str() != "true" { return 3; }

  return 0;
}
