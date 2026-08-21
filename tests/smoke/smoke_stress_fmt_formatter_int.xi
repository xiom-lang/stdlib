// XIOM stdlib stress -- xiom.fmt Formatter.write_int and finish
// Tests Formatter building a string from multiple integer writes.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_formatter_int
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_int(42);
  var out = f.finish();
  if out != "42" { return 1; }

  var f2 = fmt.Formatter.new();
  f2.write_int(0);
  var out2 = f2.finish();
  if out2 != "0" { return 2; }

  var f3 = fmt.Formatter.new();
  f3.write_int(-1);
  var out3 = f3.finish();
  if out3 != "-1" { return 3; }

  var f4 = fmt.Formatter.new();
  f4.write_int(999);
  var out4 = f4.finish();
  if out4 != "999" { return 4; }

  return 0;
}
