module smoke_stress_fmt_format2_strs
use xiom.fmt;

fn main() -> Int {
  var result = fmt.format2("{} {}", "hello", "world");
  if result.len() > 0 { return 0; } else { return 1; }
}
