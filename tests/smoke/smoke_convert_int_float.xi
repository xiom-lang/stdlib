module smoke_convert_int_float
use xiom.convert;

fn main() -> Int {
  var f = convert.int_to_float(42);
  if f < 41.9 || f > 42.1 { return 1; }

  var i = convert.float_to_int(3.14);
  if i != 3 { return 2; }

  var i2 = convert.float_to_int(-1.9);
  if i2 != -1 { return 3; }

  return 0;
}
