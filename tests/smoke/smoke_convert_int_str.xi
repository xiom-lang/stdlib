module smoke_convert_int_str
use xiom.convert;

fn main() -> Int {
  if convert.int_to_string(0) != "0" { return 1; }
  if convert.int_to_string(42) != "42" { return 2; }
  if convert.int_to_string(-10) != "-10" { return 3; }
  if convert.int_to_string(1000000) != "1000000" { return 4; }

  return 0;
}
