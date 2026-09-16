module p_fnref
use xiom.io;
fn main() -> Int {
  var f = io.read_int;
  var g = io.read_float;
  if f == g { return 1; }
  return 0;
}
