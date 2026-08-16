// bisect fmt_edge b: Formatter.new + finish only
use xiom.fmt;
fn main() -> Int {
  var f = fmt.Formatter.new();
  var s = f.finish();
  if s != "" { return 4; }
  return 0;
}
