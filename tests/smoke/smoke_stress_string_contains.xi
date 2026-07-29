// XIOM stdlib stress — xiom.string.str_contains presence/absence
// Checks substring found and not found cases.
// Returns 0 on success.

module smoke_stress_string_contains
use xiom.string;

fn main() -> Int {
  var s = "hello world";
  if xiom.string.str_contains(s, "wor") && not xiom.string.str_contains(s, "xyz") {
    return 0;
  }
  return 1;
}
