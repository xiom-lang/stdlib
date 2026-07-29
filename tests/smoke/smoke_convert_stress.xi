module smoke_convert_stress
use xiom.convert;

fn main() -> Int {
  var i: Int = -100;
  while i < 100 {
    var s = convert.int_to_string(i);
    if s == "" { return 1; }
    i = i + 1;
  }

  return 0;
}
