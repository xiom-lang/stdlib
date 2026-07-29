module smoke_fmt_stress
use xiom.fmt;

fn main() -> Int {
  var i: Int = 0;
  while i < 50 {
    var s = i.to_str();
    if s == "" { return 1; }
    i = i + 1;
  }
  return 0;
}
