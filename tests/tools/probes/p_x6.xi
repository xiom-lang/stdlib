module p_x6
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var g1 = xiom.string.glob.glob_match("*.xi", "main.xi");
  io.println("x6a=" + convert.bool_to_string(g1));
  var g2 = xiom.string.glob.glob_match("a?c", "abc");
  io.println("x6b=" + convert.bool_to_string(g2));
  return 0;
}
