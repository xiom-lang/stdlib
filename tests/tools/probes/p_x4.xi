module p_x4
use xiom.io;
use xiom.convert;
fn via(p: Str, s: Str) -> Bool { return xiom.string.glob.glob_match(p, s); }
fn main() -> Int {
  io.println("x4=" + convert.bool_to_string(via("*.xi", "main.xi")));
  return 0;
}
