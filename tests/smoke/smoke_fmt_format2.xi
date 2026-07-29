module smoke_fmt_format2
use xiom.fmt;

fn main() -> Int {
  if fmt.format2("{} {}", "hello", "world") != "hello world" { return 1; }
  if fmt.format2("{}, {}", 1, 2) != "1, 2" { return 2; }

  return 0;
}
