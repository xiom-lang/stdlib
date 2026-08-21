// XIOM stdlib stress -- xiom.regex Regex.replace replaces first match
// Tests replace for first occurrence replacement and no-match passthrough.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_replace
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new("cat") { Ok(r) => r; Err(_) => { return 1; } };

  var r1 = re.replace("a cat and a cat", "dog");
  if r1 != "a dog and a cat" { return 1; }

  var r2 = re.replace("no match here", "dog");
  if r2 != "no match here" { return 2; }

  var re_digit = match regex.Regex.new("\\d") { Ok(r) => r; Err(_) => { return 1; } };
  var r3 = re_digit.replace("abc123def", "X");
  if r3 != "abcX23def" { return 3; }

  return 0;
}
