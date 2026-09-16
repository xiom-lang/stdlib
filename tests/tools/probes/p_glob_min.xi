module p_glob_min
use xiom.io;
fn main() -> Int {
  var m1 = xiom.misc.glob.glob_match("*.xi", "a.xi");
  io.println("misc=" + (m1 as Str));
  var g1 = xiom.string.glob.glob_match("*.xi", "a.xi");
  io.println("string=" + (g1 as Str));
  return 0;
}
