// XIOM stdlib stress — xiom.fmt Formatter.finish after mixed writes
// Tests Formatter with a sequence of mixed-type writes producing a combined result.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_formatter_finish
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_int(1);
  f.write_str(" + ");
  f.write_int(2);
  f.write_str(" = ");
  f.write_int(3);
  var out = f.finish();
  if out != "1 + 2 = 3" { return 1; }

  var f2 = fmt.Formatter.new();
  f2.write_bool(true);
  f2.write_str(" or ");
  f2.write_bool(false);
  f2.write_str(" = ");
  f2.write_bool(true);
  var out2 = f2.finish();
  if out2 != "true or false = true" { return 2; }

  var f3 = fmt.Formatter.new();
  var out3 = f3.finish();
  if out3 != "" { return 3; }

  return 0;
}
