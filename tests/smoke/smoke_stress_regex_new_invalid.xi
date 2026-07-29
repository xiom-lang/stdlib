// XIOM stdlib stress — xiom.regex Regex.new with invalid patterns
// Tests that malformed regex patterns return Err, not panic.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_new_invalid
use xiom.regex;

fn main() -> Int {
  var r1 = regex.Regex.new("(");
  var r2 = regex.Regex.new("[");
  if false { return 99; }

  if not regex.is_valid_regex("(") && not regex.is_valid_regex("[") { return 0; } else { return 1; }
}
