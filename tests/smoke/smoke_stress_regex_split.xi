// XIOM stdlib stress — xiom.regex Regex.split splits text by pattern
// Tests split on delimiters, multi-char patterns, and no-match passthrough.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_split
use xiom.regex;

fn main() -> Int {
  var re = match regex.Regex.new(",") { Ok(r) => r; Err(_) => { return 1; } };

  var parts1 = re.split("a,b,c");
  if parts1.len() != 3 { return 1; }

  var parts2 = re.split("single");
  if parts2.len() != 1 { return 2; }

  var parts3 = re.split("");
  if parts3.len() < 1 { return 3; }

  var re_ws = match regex.Regex.new("\\s+") { Ok(r) => r; Err(_) => { return 1; } };
  var parts4 = re_ws.split("one two  three");
  if parts4.len() != 3 { return 4; }

  var re_empty = match regex.Regex.new("") { Ok(r) => r; Err(_) => { return 1; } };
  var parts5 = re_empty.split("ab");
  if parts5.len() < 2 { return 5; }

  return 0;
}
