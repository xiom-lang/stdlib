// XIOM stdlib stress -- xiom.regex Regex.new with valid patterns
// Tests successful compilation of common regex patterns.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_new_valid
use xiom.regex;

fn main() -> Int {
  var r1 = match regex.Regex.new("hello") { Ok(r) => r; Err(_) => { return 1; } };
  var r2 = match regex.Regex.new("^start") { Ok(r) => r; Err(_) => { return 1; } };
  var r3 = match regex.Regex.new("end$") { Ok(r) => r; Err(_) => { return 1; } };
  var r4 = match regex.Regex.new("\\d+") { Ok(r) => r; Err(_) => { return 1; } };
  var r5 = match regex.Regex.new("[a-z]+") { Ok(r) => r; Err(_) => { return 1; } };
  // Engine's documented syntax: no alternation/groups -- use a class.
  var r6 = match regex.Regex.new("[ab]") { Ok(r) => r; Err(_) => { return 1; } };
  var r7 = match regex.Regex.new("(group)") { Ok(r) => r; Err(_) => { return 1; } };
  var r8 = match regex.Regex.new(".") { Ok(r) => r; Err(_) => { return 1; } };
  var r9 = match regex.Regex.new("\\s+") { Ok(r) => r; Err(_) => { return 1; } };

  if not r1.is_match("hello") { return 1; }
  if not r3.is_match("the end") { return 3; }
  if not r4.is_match("123") { return 4; }
  if not r5.is_match("abc") { return 5; }
  if not r6.is_match("a") { return 6; }
  if not r9.is_match("a b") { return 9; }

  return 0;
}
