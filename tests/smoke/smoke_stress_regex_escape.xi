// XIOM stdlib stress -- xiom.regex regex_escape escapes special chars
// Tests that escaped strings are treated as literals by Regex.
// Returns 0 on success, nonzero on failure.

module smoke_stress_regex_escape
use xiom.regex;

fn main() -> Int {
  var escaped = regex.regex_escape("a.b*c+?^$()[]{}|");

  var re = match regex.Regex.new(escaped) { Ok(r) => r; Err(_) => { return 1; } };
  if re.is_match("a.b*c+?^$()[]{}|") { } else { return 1; }

  if re.is_match("aXb") { return 2; } else { }

  var escaped2 = regex.regex_escape("hello.world");
  if escaped2.len() == 0 { return 3; }

  return 0;
}
