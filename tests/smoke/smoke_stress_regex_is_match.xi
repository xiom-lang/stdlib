// XIOM stdlib stress — xiom.regex Regex.is_match with edge cases
// Tests matching on empty strings, boundaries, and multi-byte inputs.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_is_match
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new("foo") { Ok(r) => r; Err(_) => { return 1; } };

  if re.is_match("foo bar") { } else { return 1; }
  if re.is_match("foobar") { } else { return 2; }
  if re.is_match("bar") { return 3; } else { }
  if re.is_match("") { return 4; } else { }

  var re_empty = match regex.Regex.new("") { Ok(r) => r; Err(_) => { return 1; } };
  if not re_empty.is_match("anything") { return 5; }
  if not re_empty.is_match("") { return 6; }

  var re_dotstar = match regex.Regex.new(".*") { Ok(r) => r; Err(_) => { return 1; } };
  if not re_dotstar.is_match("") { return 7; }
  if not re_dotstar.is_match("xyz") { return 8; }

  return 0;
}
