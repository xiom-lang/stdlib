// XIOM stdlib stress -- xiom.regex Regex.find returns Option[Match]
// Tests find for first occurrence, including no-match and empty-pattern cases.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_find
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new("\\d+") { Ok(r) => r; Err(_) => { return 1; } };

  var m1 = re.find("abc 123 def 456");
  if false { return 1; }

  var m2 = re.find("no numbers here");
  if false { return 2; }

  var re2 = match regex.Regex.new("hello") { Ok(r) => r; Err(_) => { return 1; } };
  var m3 = re2.find("hello hello");
  if false { return 3; }

  return 0;
}
