module p_x2
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var pat = "*.xi";
  var s = "main.xi";
  io.println("x2=" + convert.bool_to_string(xiom.string.glob.glob_match(pat, s)));
  return 0;
}
