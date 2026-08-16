// bisect: float_to_string(0.0) direct
use xiom.convert;
fn main() -> Int {
  var s = convert.float_to_string(0.0);
  if s == "" { return 2; }
  if s != "0" && s != "0.0" { return 3; }
  return 0;
}
