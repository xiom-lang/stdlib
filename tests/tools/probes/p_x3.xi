module p_x3
use xiom.io;
use xiom.convert;
fn main() -> Int {
  io.println("x3=" + convert.bool_to_string(xiom.misc.glob.glob_match("*.xi", "main.xi")));
  return 0;
}
