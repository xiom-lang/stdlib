module smoke_fmt_types
use xiom.fmt;

fn main() -> Int {
  var i_val: Int = 42;
  if i_val.to_str() != "42" { return 1; }

  var f_val: Float64 = 3.14;
  var fs = f_val.to_str();
  if fs == "" { return 2; }

  var b_val: Bool = false;
  if b_val.to_str() != "false" { return 3; }

  if "xiom".to_str() != "xiom" { return 4; }

  return 0;
}
