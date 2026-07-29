module smoke_stress_regex_escape_special
use xiom.regex;

fn main() -> Int {
  var escaped = regex.regex_escape("hello.world[test]*");
  if escaped.len() > 0 { return 0; } else { return 1; }
}
