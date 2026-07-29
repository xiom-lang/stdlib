module smoke_fmt_format3
use xiom.fmt;

fn main() -> Int {
  if fmt.format3("{} {} {}", 1, 2, 3) != "1 2 3" { return 1; }
  if fmt.format3("{}, {}, {}", "a", "b", "c") != "a, b, c" { return 2; }

  return 0;
}
