module smoke_convert_identity
use xiom.convert;

fn main() -> Int {
  if convert.identity(42) != 42 { return 1; }
  if convert.identity("hello") != "hello" { return 2; }
  if convert.identity(true) != true { return 3; }
  if convert.identity(3.14) != 3.14 { return 4; }

  return 0;
}
