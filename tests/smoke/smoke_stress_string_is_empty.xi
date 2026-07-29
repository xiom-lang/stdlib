// XIOM stdlib stress — xiom.string.is_empty true/false
// Tests empty string returns true and non-empty returns false.
// Returns 0 on success.

module smoke_stress_string_is_empty
use xiom.string;

fn main() -> Int {
  if xiom.string.is_empty("") && not xiom.string.is_empty("x") {
    return 0;
  }
  return 1;
}
