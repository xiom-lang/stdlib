module smoke_fmt_format_all
use xiom.fmt;

fn main() -> Int {
  var s1 = fmt.format1("int: {}", 42);
  if s1 != "int: 42" { return 1; }

  var s2 = fmt.format2("{} and {}", 1, 2);
  if s2 != "1 and 2" { return 2; }

  var s3 = fmt.format3("{}, {}, {}", "a", "b", "c");
  if s3 != "a, b, c" { return 3; }

  if true.to_str() != "true" { return 4; }
  if false.to_str() != "false" { return 5; }

  return 0;
}
