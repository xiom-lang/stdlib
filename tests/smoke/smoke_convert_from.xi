module smoke_convert_from
use xiom.convert;

fn main() -> Int {
  var s = convert.int_to_string(42);
  if s != "42" { return 1; }

  var b = convert.bool_to_string(true);
  if b != "true" { return 2; }

  var f = convert.int_to_float(10);
  if f < 9.9 || f > 10.1 { return 3; }

  var i = convert.float_to_int(10.9);
  if i != 10 { return 4; }

  return 0;
}
