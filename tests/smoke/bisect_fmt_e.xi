// fmt_edge combo: to_str + Formatter
use xiom.fmt;
fn main() -> Int {
  if "".to_str() != "" { return 1; }
  var f = fmt.Formatter.new();
  var s = f.finish();
  if s != "" { return 4; }
  return 0;
}
