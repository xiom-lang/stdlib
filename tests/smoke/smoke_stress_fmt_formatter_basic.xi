module smoke_stress_fmt_formatter_basic
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_str("test");
  var s = f.finish();
  if s == "test" { return 0; } else { return 1; }
}
