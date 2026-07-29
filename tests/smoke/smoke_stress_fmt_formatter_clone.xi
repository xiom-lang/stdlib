module smoke_stress_fmt_formatter_clone
use xiom.fmt;

fn main() -> Int {
  var f1 = fmt.Formatter.new();
  f1.write_str("original");
  var f2 = f1.clone();
  f2.write_str("_modified");
  var s1 = f1.finish();
  var s2 = f2.finish();
  if s1 == "original" {
    if s2 == "original_modified" { return 0; } else { return 2; }
  } else { return 1; }
}
