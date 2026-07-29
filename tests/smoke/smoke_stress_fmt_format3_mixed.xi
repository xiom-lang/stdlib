module smoke_stress_fmt_format3_mixed
use xiom.fmt;

fn main() -> Int {
  var result = fmt.format3("{} {} {}", "hello", 42.to_str(), 3.14.to_str());
  if result.len() > 0 { return 0; } else { return 1; }
}
