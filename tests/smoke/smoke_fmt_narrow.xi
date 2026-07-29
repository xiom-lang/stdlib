module smoke_fmt_narrow
use xiom.fmt;

fn main() -> Int {
  var n8: Int8 = 100 as Int8;
  if n8.to_str() != "100" { return 1; }

  var n16: Int16 = 30000 as Int16;
  if n16.to_str() == "" { return 2; }

  var n32: Int32 = 1000000 as Int32;
  if n32.to_str() == "" { return 3; }

  return 0;
}
