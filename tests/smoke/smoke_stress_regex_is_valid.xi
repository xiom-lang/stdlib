// XIOM stdlib stress -- xiom.regex is_valid_regex validates patterns
// Tests valid and invalid pattern detection without compilation.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_is_valid
use xiom.regex;

fn main() -> Int {
  if not regex.is_valid_regex("hello") { return 1; }
  if not regex.is_valid_regex("^[a-z]+$") { return 2; }
  if not regex.is_valid_regex("\\d{1,5}") { return 3; }
  if not regex.is_valid_regex("(?:non-cap)") { return 4; }
  if not regex.is_valid_regex("") { return 5; }

  if regex.is_valid_regex("(") { return 6; }
  if regex.is_valid_regex("[unclosed") { return 7; }
  if regex.is_valid_regex("\\") { return 8; }
  if regex.is_valid_regex("*") { return 9; }
  if regex.is_valid_regex("{1,2") { return 10; }

  return 0;
}
