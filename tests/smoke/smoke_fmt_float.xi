module smoke_fmt_float
use xiom.fmt;

fn main() -> Int {
  var s = 3.14.to_str();
  if s == "" { return 1; }

  var s2 = 0.0.to_str();
  if s2 == "" { return 2; }

  var s3 = (-1.5).to_str();
  if s3 == "" { return 3; }

  return 0;
}
