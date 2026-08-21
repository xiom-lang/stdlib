// XIOM stdlib stress -- xiom.fmt Formatter.write_float and finish
// Tests Formatter building a string from float writes.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_formatter_float
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_float(3.14);
  var out = f.finish();
  if out.len() == 0 { return 1; }

  var f2 = fmt.Formatter.new();
  f2.write_float(0.0);
  var out2 = f2.finish();
  if out2.len() == 0 { return 2; }

  var f3 = fmt.Formatter.new();
  f3.write_float(-2.5);
  var out3 = f3.finish();
  if out3.len() == 0 { return 3; }

  var f4 = fmt.Formatter.new();
  f4.write_float(1e6);
  var out4 = f4.finish();
  if out4.len() == 0 { return 4; }

  return 0;
}
