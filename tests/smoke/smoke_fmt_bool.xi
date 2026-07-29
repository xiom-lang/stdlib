module smoke_fmt_bool
use xiom.fmt;

fn main() -> Int {
  if true.to_str() != "true" { return 1; }
  if false.to_str() != "false" { return 2; }

  return 0;
}
