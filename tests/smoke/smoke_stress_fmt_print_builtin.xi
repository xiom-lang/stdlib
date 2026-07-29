module smoke_stress_fmt_print_builtin
use xiom.fmt;

fn main() -> Int {
  fmt.print("hello");
  fmt.println("world");
  return 0;
}
