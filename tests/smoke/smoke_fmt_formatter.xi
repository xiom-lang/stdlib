module smoke_fmt_formatter
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_int(42);
  f.write_str(" ");
  f.write_bool(true);
  f.write_str(" ");
  f.write_float(3.14);
  var s = f.finish();
  if s == "" { return 1; }

  return 0;
}
