// combo 2: Formatter + Int.to_str (no Str.to_str)
use xiom.fmt;
fn main() -> Int {
  if 0.to_str() != "0" { return 2; }
  var f = fmt.Formatter.new();
  var s = f.finish();
  if s != "" { return 4; }
  return 0;
}
