module smoke_convert_edge
use xiom.convert;

fn main() -> Int {
  if convert.int_to_string(0) != "0" { return 1; }
  if convert.int_to_string(1) != "1" { return 2; }
  if convert.int_to_string(-1) != "-1" { return 3; }

  if convert.bool_to_string(true) != "true" { return 4; }

  var s = convert.float_to_string(0.5);
  if s == "" { return 5; }

  match convert.int_to_char(32) {
    Some(_) => {},
    None => { return 6; },
  };

  return 0;
}
