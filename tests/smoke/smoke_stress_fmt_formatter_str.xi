// XIOM stdlib stress -- xiom.fmt Formatter.write_str and finish
// Tests Formatter building a string from string writes.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_formatter_str
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_str("hello");
  var out = f.finish();
  if out != "hello" { return 1; }

  var f2 = fmt.Formatter.new();
  f2.write_str("");
  var out2 = f2.finish();
  if out2 != "" { return 2; }

  var f3 = fmt.Formatter.new();
  f3.write_str("multi\nline");
  var out3 = f3.finish();
  if out3 != "multi\nline" { return 3; }

  var f4 = fmt.Formatter.new();
  f4.write_str("a");
  f4.write_str("b");
  f4.write_str("c");
  var out4 = f4.finish();
  if out4 != "abc" { return 4; }

  return 0;
}
