// combo 3: Formatter + Float64.to_str
use xiom.fmt;
fn main() -> Int {
  if 1.5.to_str() != "1.5" { return 5; }
  var f = fmt.Formatter.new();
  var s = f.finish();
  if s != "" { return 4; }
  return 0;
}
