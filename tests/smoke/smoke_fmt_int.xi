module smoke_fmt_int
use xiom.fmt;

fn main() -> Int {
  if 42.to_str() != "42" { return 1; }
  if 0.to_str() != "0" { return 2; }
  if (-1).to_str() != "-1" { return 3; }

  return 0;
}
