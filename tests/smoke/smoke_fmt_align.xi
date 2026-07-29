module smoke_fmt_align
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_int(42);
  var s = f.finish();
  if s != "42" { return 1; }

  return 0;
}
