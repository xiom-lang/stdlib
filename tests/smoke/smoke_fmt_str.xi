module smoke_fmt_str
use xiom.fmt;

fn main() -> Int {
  if "hello".to_str() != "hello" { return 1; }
  if "".to_str() != "" { return 2; }

  return 0;
}
