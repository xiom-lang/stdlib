// XIOM stdlib stress — xiom.regex Regex.find_all collects all matches
// Tests find_all on text with multiple, single, and zero matches.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_find_all
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new("\\d+") { Ok(r) => r; Err(_) => { return 1; } };

  var all1 = re.find_all("a1 b22 c333");
  if all1.len() != 3 { return 1; }

  var all2 = re.find_all("no digits");
  if all2.len() != 0 { return 2; }

  var re2 = match regex.Regex.new("x.*?x") { Ok(r) => r; Err(_) => { return 1; } };
  var all3 = re2.find_all("xax xbx xcxd");
  if all3.len() < 2 { return 3; }

  return 0;
}
