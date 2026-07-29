module smoke_convert_bool_str
use xiom.convert;

fn main() -> Int {
  if convert.bool_to_string(true) != "true" { return 1; }
  if convert.bool_to_string(false) != "false" { return 2; }

  return 0;
}
