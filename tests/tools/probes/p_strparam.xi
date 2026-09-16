module p_strparam
use xiom.io;
use xiom.convert;
fn f(s: Str) -> Int {
  let t = s.trim();
  io.println("len=" + convert.int_to_string(t.len()) + " b0=" + convert.int_to_string(t.byte_at(0) as Int) + " b1=" + convert.int_to_string(t.byte_at(1) as Int));
  return t.byte_at(0) as Int;
}
fn main() -> Int {
  var r = f("42");
  io.println("r=" + convert.int_to_string(r));
  return 0;
}
