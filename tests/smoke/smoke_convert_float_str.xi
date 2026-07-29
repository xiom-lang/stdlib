module smoke_convert_float_str
use xiom.convert;

fn main() -> Int {
  var s1 = convert.float_to_string(3.14);
  if s1 == "" { return 1; }

  var s2 = convert.float_to_string(0.0);
  if s2 == "" { return 2; }

  var s3 = convert.float_to_string(-1.5);
  if s3 == "" { return 3; }

  return 0;
}
