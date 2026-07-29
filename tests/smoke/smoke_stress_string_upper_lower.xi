// XIOM stdlib stress — xiom.string.str_upper / str_lower
// Converts mixed-case strings to upper and lower, verifies results.
// Returns 0 on success.

module smoke_stress_string_upper_lower
use xiom.string;

fn main() -> Int {
  var s = "Hello World";
  if xiom.string.str_upper(s) == "HELLO WORLD"
     && xiom.string.str_lower(s) == "hello world" {
    return 0;
  }
  return 1;
}
