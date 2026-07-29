module smoke_stress_fmt_formatter_chain
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_str("hello");
  f.write_str(" ");
  f.write_str("world");
  var s = f.finish();
  if s == "hello world" { return 0; } else { return 1; }
}
