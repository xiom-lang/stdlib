module smoke_convert_string
use xiom.convert;

fn main() -> Int {
  var s = convert.int_to_string(12345);
  var s2 = convert.int_to_string(12345);
  if s != s2 { return 1; }

  var s3 = convert.float_to_string(1.0);
  if s3 == "" { return 2; }

  if convert.bool_to_string(false) != "false" { return 3; }

  return 0;
}
