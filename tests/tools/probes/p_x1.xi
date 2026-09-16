module p_x1
use xiom.io;
use xiom.convert;
fn main() -> Int {
  io.println("x1=" + convert.bool_to_string(xiom.string.glob.glob_match("*.xi", "main.xi")));
  return 0;
}
