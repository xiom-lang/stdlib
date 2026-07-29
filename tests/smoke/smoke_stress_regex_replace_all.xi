// XIOM stdlib stress — xiom.regex Regex.replace_all replaces all matches
// Tests replace_all for full replacement and empty-text edge case.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_replace_all
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new("dog") { Ok(r) => r; Err(_) => { return 1; } };

  var r1 = re.replace_all("dog dog dog", "cat");
  if r1 != "cat cat cat" { return 1; }

  var r2 = re.replace_all("no match", "cat");
  if r2 != "no match" { return 2; }

  var r3 = re.replace_all("", "x");
  if r3 != "" { return 3; }

  var re_d = match regex.Regex.new("\\d") { Ok(r) => r; Err(_) => { return 1; } };
  var r4 = re_d.replace_all("a1b2c3", "_");
  if r4 != "a_b_c_" { return 4; }

  return 0;
}
