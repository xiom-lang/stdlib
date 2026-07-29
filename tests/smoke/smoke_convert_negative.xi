module smoke_convert_negative
use xiom.convert;

fn main() -> Int {
  if convert.int_to_string(-100) != "-100" { return 1; }
  if convert.int_to_string(-1) != "-1" { return 2; }

  var i = convert.float_to_int(-3.14);
  if i != -3 { return 3; }

  var f = convert.int_to_float(-42);
  if f > -41.9 && f < -42.1 { return 4; }

  return 0;
}
