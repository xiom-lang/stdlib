module smoke_fmt_edge
use xiom.fmt;

fn main() -> Int {
  if "".to_str() != "" { return 1; }
  if 0.to_str() != "0" { return 2; }
  if (-0).to_str() != "0" { return 3; }

  var f = fmt.Formatter.new();
  var s = f.finish();
  if s != "" { return 4; }

  return 0;
}
