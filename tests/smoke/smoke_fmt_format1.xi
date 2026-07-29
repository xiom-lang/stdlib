module smoke_fmt_format1
use xiom.fmt;

fn main() -> Int {
  if fmt.format1("hello {}", "world") != "hello world" { return 1; }
  if fmt.format1("{} {}", "first") != "first {}" { return 2; }
  if fmt.format1("no placeholder", "x") != "no placeholder" { return 3; }
  if fmt.format1("{}", 42) != "42" { return 4; }
  if fmt.format1("{}", true) != "true" { return 5; }

  return 0;
}
