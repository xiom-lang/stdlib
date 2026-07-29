// XIOM stdlib stress — xiom.string.str_starts_with / str_ends_with
// Tests prefix/suffix matching with true and false cases.
// Returns 0 on success.

module smoke_stress_string_starts_ends
use xiom.string;

fn main() -> Int {
  var s = "hello world";
  if xiom.string.str_starts_with(s, "hello") && xiom.string.str_ends_with(s, "world")
     && not xiom.string.str_starts_with(s, "world") && not xiom.string.str_ends_with(s, "hello") {
    return 0;
  }
  return 1;
}
