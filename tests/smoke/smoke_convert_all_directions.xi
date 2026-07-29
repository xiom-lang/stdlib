module smoke_convert_all_directions
use xiom.convert;
use xiom.core;

fn main() -> Int {
  if convert.int_to_string(0) != "0" { return 1; }
  if convert.bool_to_string(true) != "true" { return 2; }

  var s = convert.float_to_string(1.0);
  if s == "" { return 3; }

  if convert.char_to_int('9') != 57 { return 4; }

  var f = convert.int_to_float(100);
  if f < 99.9 || f > 100.1 { return 5; }

  var i = convert.float_to_int(100.0);
  if i != 100 { return 6; }

  return 0;
}
