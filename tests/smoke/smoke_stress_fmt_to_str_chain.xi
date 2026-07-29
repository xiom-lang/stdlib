module smoke_stress_fmt_to_str_chain
use xiom.fmt;

fn main() -> Int {
  var s1 = 42.to_str();
  var s2 = true.to_str();
  var s3 = 3.14.to_str();
  if s1.len() > 0 {
    if s2.len() > 0 {
      if s3.len() > 0 { return 0; } else { return 3; }
    } else { return 2; }
  } else { return 1; }
}
